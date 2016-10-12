﻿param (
  [string]$adAdminPassword,
  [string]$clientAdminPassword
)

# Import Azure Service Management module
Import-Module Azure
Import-Module AzureRM

function Get-RandomString ($length) {
  $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
  $result = ""
  for ($x = 0; $x -lt $Length; $x++) {
    $result += $set | Get-Random
  }
  return $result
}

# DC Variables
$URI                        = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/azuredeploy.json'
$_artifactsLocation         = "https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/"
$location                   = 'eastus2'
$locationName               = "East US"
$studentCode                = "a" + (Get-RandomString 6)
$resourceGroupName          = $studentCode + '.evil.training'
$adAdminUserName            = "EvilAdmin"
$domainName                 = "ad.evil.training"
$dnsPrefix                  = $studentCode
$storageAccountName         = $studentCode + "storage"    # Lowercase required
$adVMName                   = $studentCode + "-dc01"
$adAvailabilitySetName      = $studentCode + "AvailSet"
$adNicName                  = $studentCode + "-dc01nic"
$adNicIPAddress             = "10.0.0.4"
$adSubnetName               = $studentCode + "subnet"
$adSubnetAddressPrefix      = "10.0.0.0/24"
$virtualNetworkName         = $studentCode + "vnet"
$virtualNetworkAddressRange = "10.0.0.0/16"
$publicIPAddressName        = $studentCode + "-dc01pip"
$adVmSize                   = "Basic_A1"

# Client Vars
$clientDnsPrefix            = $studentCode + "-home"
$clientAdminUsername        = "localAdmin"
$clientNicIpAddress         = "10.0.0.10"
$clientVMSize               = "Basic_A2"


# Server Vars
$serverDnsPrefix            = $studentCode+"-srv"
$serverNicIpAddress         = "10.0.0.11"
$serverVMSize               = "Basic_A1"

# Linux Vars
$linuxVMName                = $studentCode+"-lnx"
$linuxNicName               = $studentCode+"-lnx-nic"
$linuxOSDiskName            = $studentCode+"-lnx-os"
$linuxDataDiskName          = $studentCode+"-lnx-data"
$linuxNicIpAddress          = "10.0.0.12"
$linuxPublicIPAddressName   = $studentCode+"-lnx-pip"
$linuxVMSize                = "Basic_A2"

# Check that the public dns $addnsName is available
try {
  if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $location)
  { 
    'Available' 
  } 
  else 
  { 
    'Taken. addnsName must be globally unique.' 
    break
  }
}
catch {
  Login-AzureRmAccount
  if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $location)
  { 
    'Available' 
  } 
  else 
  { 
    'Taken. addnsName must be globally unique.' 
    break
  }
}

# Create the new resource group. Runs quickly.
try {
  Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
}
catch {
  New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

# Parameters for the template and configuration
$MyParams = @{
  adAdminUsername             = $adAdminUserName
  adAdminPassword             = $adAdminPassword
  domainName                  = $domainName
  dnsPrefix                   = $dnsPrefix
  virtualNetworkName          = $virtualNetworkName
  storageAccountName          = $storageAccountName
  adNicName                   = $adNicName
  adNicIpAddress              = $adNicIPAddress
  adVMName                    = $adVMName
  adVMSize                    = $adVMSize
  adSubnetName                = $adSubnetName
  publicIPAddressName         = $publicIPAddressName
  adAvailabilitySetname       = $adAvailabilitySetName
  virtualNetworkAddressRange  = $virtualNetworkAddressRange
  adSubnetAddressPrefix       = $adSubnetAddressPrefix
  _artifactsLocation          = $_artifactsLocation
  clientDnsPrefix             = $clientDnsPrefix
  clientAdminUsername         = $clientAdminUsername
  clientAdminPassword         = $clientAdminPassword
  clientNicIpAddress          = $clientNicIpAddress
  clientVmSize                = $clientVMSize
}

# Splat the parameters on New-AzureRmResourceGroupDeployment  
$SplatParams = @{
  TemplateUri                 = $URI 
  ResourceGroupName           = $resourceGroupName 
  TemplateParameterObject     = $MyParams
  Name                        = $studentCode + "-template"
}

# This takes ~30 minutes
# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose