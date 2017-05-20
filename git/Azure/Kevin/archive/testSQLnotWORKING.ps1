
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

New-AzureRmResourceGroup -Name 'mymymymy' -Location 'East US 2'
$newSubnetParams = @{
	'Name' = 'MySubnet'
	'AddressPrefix' = '10.3.1.0/24'
}
$subnet = New-AzureRmVirtualNetworkSubnetConfig @newSubnetParams
$newVNetParams = @{
	'Name' = 'MyNetwork'
	'ResourceGroupName' = 'mymymymy'
	'Location' = 'East US 2'
	'AddressPrefix' = '10.3.0.0/16'
	'Subnet' = $subnet
}
$vNet = New-AzureRmVirtualNetwork @newVNetParams
$newStorageAcctParams = @{
	'Name' = 'bluefourgoosoo'
	'ResourceGroupName' = 'mymymymy'
	'Type' = 'Standard_LRS'
	'Location' = 'East US 2'
}
$storageAccount = New-AzureRmStorageAccount @newStorageAcctParams -Verbose

$newPublicIpParams = @{
	'Name' = 'MyPublicIP'
	'ResourceGroupName' = 'mymymymy'
	'AllocationMethod' = 'Dynamic' ## Dynamic or Static
	'Location' = 'East US 2'
}
$publicIp = New-AzureRmPublicIpAddress @newPublicIpParams
$newVNicParams = @{
	'Name' = 'MyNic'
	'ResourceGroupName' = 'mymymymy'
	'Location' = 'East US 2'
	'SubnetId' = $vNet.Subnets[0].Id
	'PublicIpAddressId' = $publicIp.Id
}
$vNic = New-AzureRmNetworkInterface @newVNicParams
$newConfigParams = @{
	'VMName' = 'gogogad'
	'VMSize' = 'Standard_A1'
}
$vmConfig = New-AzureRmVMConfig @newConfigParams
$newVmOsParams = @{
	'Windows' = $true
	'ComputerName' = 'MyVM'
	'Credential' = (Get-Credential -Message 'Type the name and password of the local administrator account.')
	'ProvisionVMAgent' = $true
	'EnableAutoUpdate' = $true
}
$vm = Set-AzureRmVMOperatingSystem @newVmOsParams -VM $vmConfig
$newSourceImageParams = @{
	'PublisherName' = 'MicrosoftWindowsServer'
	'Version' = 'latest'
	'Skus' = '2012-R2-Datacenter'
	'VM' = $vm
}
 
$offer = Get-AzureRmVMImageOffer -Location 'East US 2' -PublisherName 'MicrosoftWindowsServer'
$vm = Set-AzureRmVMSourceImage @newSourceImageParams -Offer $offer.Offer
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $vNic.Id
# $storageAccount = $storageAccount.PrimaryEndpoints.Blob.ToString()
$osDiskUri = "https://bluefourgoosoo.blob.core.windows.net/vhds/bluefourgoosoo.vhd"
 
$newOsDiskParams = @{
	'Name' = 'OSDisk'
	'CreateOption' = 'fromImage'
	'VM' = $vm
	'VhdUri' = $osDiskUri
}
 
$vm = Set-AzureRmVMOSDisk @newOsDiskParams
$newVmParams = @{
	'ResourceGroupName' = 'mymymymy'
	'Location' = 'East US 2'
	'VM' = $vm
}
New-AzureRmVM @newVmParams