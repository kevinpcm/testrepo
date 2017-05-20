<#
Deploy-ExistingVHD-ToAzure.ps1
Version: 2016.11.07.01

NOTE:  The Public IP and NSG are not completed in this version
Needs to incorporate availability sets for the 2 Vms
#>

$subscriptionId         = 'd2fc1b6f-162c-4553-b423-6c8b9902819e'
$tenantid               = 'ffefc0c4-2ef8-49f8-a251-907971968a26'
$sourceOSImageUri       = 'https://gosa01.blob.core.windows.net/template/Azure_disk_1.vhd'

$nicResourceGroupName   = "RG01"
$vmNames                = ("USAZEBHFV0001","USAZEBHFV0002")


# same size for all VMs
$vmSize                 = "Standard_A1"
$vmResourceGroupName    = "BHF_USEast_1"
$virtualNetworkName     = "VN01"

$adminUsername          = 'bhfadmin1'
$adminPassword          = 'Br1ghtH0us3Fin@nci@l$456'

# Enable verbose output and stop on error
$VerbosePreference      = 'Continue'
$ErrorActionPreference  = 'Stop'

#===============================================================

Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionID $subscriptionId

$resourceGroupName = $storageAccount.ResourceGroupName
$location = $storageAccount.Location

foreach ($vmName in $vmNames) {
    $nicName = "$vmName-NIC"
    $pipName = "$vmName-pip1"
    $storageAccountName = "$vmname-sa"

    $storageAccount = Get-AzureRMStorageAccount -ResourceGroupName $vmResourceGroupName -Name $storageAccountName 

    Write-Output 'Adding subnet to Virtual Network'  
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $nicResourceGroupName -Name $virtualNetworkName
    
    Write-Output "Creating NIC - $nicName"  
    $nic = New-AzureRMNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $vnet.Subnets[0].Id 
    $pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $vmResourceGroupName -Location $Location -AllocationMethod Static

    Write-Output 'Creating VM Config'  
    $vmconfig = New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize 

    $cred = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force) 

    # NOTE: Depending on what OS you deploying either -Linux or -Windows switch.
    $vmconfig = Set-AzureRMVMOperatingSystem -VM $vmconfig -Windows -ComputerName $vmName -Credential $cred #-ProvisionVMAgent -EnableAutoUpdate

    #$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $Location -SubnetId $subnet -PublicIpAddressId $pip.Id -PrivateIpAddress $privIP
    $vmconfig = Add-AzureRMVMNetworkInterface -VM $vmconfig -Id $nic.Id

    $OSdiskName = 'osdisk'
    $osDiskUri  = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $OSdiskName
    $vmconfig   = Set-AzureRMVMOSDisk -VM $vmconfig -Name $OSdiskName -VhdUri $osDiskUri -SourceImageUri $sourceOSImageUri -CreateOption FromImage -Windows

    #Specify the Data disk
    $DatadiskName = "$vmName-datadisk"
    $dataDiskUri  = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $DatadiskName
    $vmconfig     = Add-AzureRMVMDataDisk -VM $vmconfig -Name $DatadiskName -VhdUri $dataDiskUri -DiskSizeInGB 60 -CreateOption Empty -Lun 0

    $asName = "BHFADDS1"
    Write-Output "creating availability set $asname"
    if (!(Get-AzureRmAvailabilitySet -ResourceGroupName $vmResourceGroupName -Name $asName)) {
        $aset1 = New-AzureRmAvailabilitySet -ResourceGroupName $vmResourceGroupName -Name $asname -Location $location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2
    }

    Write-Output "Creating VM ($vmName)... "
    New-AzureRMVM -ResourceGroupName $vmResourceGroupName -Location $location -VM $vmconfig
}
