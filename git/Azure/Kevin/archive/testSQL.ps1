
param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "kevin@thenext.net",
    [parameter(Mandatory=$False)] [string] $azTenId    = "ffefc0c4-2ef8-49f8-a251-907971968a26",
    [parameter(Mandatory=$False)] [string] $azSubId    = "d2fc1b6f-162c-4553-b423-6c8b9902819e",
    [parameter(Mandatory=$False)] [string] $InputFile  = "kevintest.csv"
)

Write-Output "checking if session is authenticated..."
if ($azCred -eq $null) {
    Write-Output "authentication is required."
    $azCred = Login-AzureRmAccount -EnvironmentName $azEnv -AccountId $azAcct -SubscriptionId $azSubId -TenantId $azTenId
}
else {
    Write-Output "authentication already confirmed."
}

New-AzureRmResourceGroup -Name 'eatresourcegroups' -Location 'East US 2'
$newSubnetParams = @{
	'Name' = 'MySubnet6'
	'AddressPrefix' = '10.6.1.0/24'
}
$subnet = New-AzureRmVirtualNetworkSubnetConfig @newSubnetParams
$newVNetParams = @{
	'Name' = 'MyNetwork6'
	'ResourceGroupName' = 'eatresourcegroups'
	'Location' = 'East US 2'
	'AddressPrefix' = '10.6.0.0/16'
	'Subnet' = $subnet
}
$vNet = New-AzureRmVirtualNetwork @newVNetParams
$newStorageAcctParams = @{
	'Name' = 'eatstorageaccountsyum'
	'ResourceGroupName' = 'eatresourcegroups'
	'Type' = 'Premium_LRS'
	'Location' = 'East US 2'
}
$storageAccount = New-AzureRmStorageAccount @newStorageAcctParams -Verbose

$newPublicIpParams = @{
	'Name' = 'MyPublicIP5'
	'ResourceGroupName' = 'eatresourcegroups'
	'AllocationMethod' = 'Dynamic' ## Dynamic or Static
	'Location' = 'East US 2'
}
$publicIp = New-AzureRmPublicIpAddress @newPublicIpParams
$newVNicParams = @{
	'Name' = 'MyNic'
	'ResourceGroupName' = 'eatresourcegroups'
	'Location' = 'East US 2'
	'SubnetId' = $vNet.Subnets[0].Id
	'PublicIpAddressId' = $publicIp.Id
}
$vNic = New-AzureRmNetworkInterface @newVNicParams
$newConfigParams = @{
	'VMName' = 'gogogad433'
	'VMSize' = 'Standard_DS13'
}
$vmConfig = New-AzureRmVMConfig @newConfigParams
$newVmOsParams = @{
	'Windows' = $true
	'ComputerName' = 'gogogad433'
	'Credential' = (Get-Credential -Message 'Type the name and password of the local administrator account.')
	'ProvisionVMAgent' = $true
	'EnableAutoUpdate' = $true
}
$vm = Set-AzureRmVMOperatingSystem @newVmOsParams -VM $vmConfig
$newSourceImageParams = @{
	'PublisherName' = 'MicrosoftSQLServer'
	'Version' = 'latest'
	'Offer' = 'SQL2012SP3-WS2012R2-BYOL'
	'Skus' = 'Standard'
	'VM' = $vm
}
 
# $offer = Get-AzureRmVMImageOffer -Location 'East US 2' -PublisherName 'MicrosoftWindowsServer'
$vm = Set-AzureRmVMSourceImage @newSourceImageParams
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $vNic.Id
# $storageAccount = $storageAccount.PrimaryEndpoints.Blob.ToString()
$osDiskUri = "https://eatstorageaccountsyum.blob.core.windows.net/vhds/eatstorageaccountsyum.vhd"
 
$newOsDiskParams = @{
	'Name' = 'OSDisk'
	'CreateOption' = 'fromImage'
	'VM' = $vm
	'VhdUri' = $osDiskUri
}
 
$vm = Set-AzureRmVMOSDisk @newOsDiskParams
$newVmParams = @{
	'ResourceGroupName' = 'eatresourcegroups'
	'Location' = 'East US 2'
	'VM' = $vm
}
New-AzureRmVM @newVmParams