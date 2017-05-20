# referenced: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-ps-create/

param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "kevin.blumenfeld@pcm.com",
    [parameter(Mandatory=$False)] [string] $azTenId    = "ffefc0c4-2ef8-49f8-a251-907971968a26",
    [parameter(Mandatory=$False)] [string] $azSubId    = "241b09aa-8028-4a27-9e25-fc560a928624",
    [parameter(Mandatory=$False)] [string] $InputFile  = "azure.csv"
)

Write-Output "checking if session is authenticated..."
if ($azCred -eq $null) {
    Write-Output "authentication is required."
    $azCred = Login-AzureRmAccount -EnvironmentName $azEnv -AccountId $azAcct -SubscriptionId $azSubId -TenantId $azTenId
}
else {
    Write-Output "authentication already confirmed."
}

Write-Output "reading input file: $InputFile..."
$csvData = Import-Csv $InputFile

if ($csvData -ne $null) {
#   if ($LocalUser -eq $null) {
#       Write-Output "setting credentials for local administrator account..."
#       $LocalUser = Get-Credential -Message "Type the name and password of the local administrator account."
#   }

    foreach ($row in $csvData) {
        $Location   = $row.Location
		$vmName     = $row.Name
        $sourceCont = $row.sourceContainer
        $sourceVHD  = $row.SourceVHD
        $destCont   = $row.destinationContainer
		$osDiskUri  = $row.osdiskUri
		$saName     = $row.StorageAccount
        $vmSize     = $row.Size
        $privIP     = $row.PrivateIP
        $vnetName   = $row.vnetName
        $subnetName = $row.SubnetName
        $subnetPfx  = $row.SubnetRange
        $addressPfx = $row.AddressRange
        $rgstore    = $row.StorageResGroup
        $rgnet      = $row.NetworkingResGroup
        $rgName     = $row.ResourceGroup
        $nicName    = "$vmName"+"nic1"
        $osdiskname = "$vmName"+"os.vhd"
        $diskName   = "$vmName"+"osdisk"
        $ipName     = "$vmName"+"pip1"
       
        if ($vmName.Substring(0,1) -ne ";") {
# Resource Group
            $rg = Get-AzureRmResourceGroup -Name $rgName -Location $Location -ErrorAction SilentlyContinue
            if ($rg -eq $null) {
                Write-Output "creating resource group: $rgName..."
                $rg = New-AzureRmResourceGroup -Name $rgName -Location $Location
            }
            else {
                Write-Output "resource group already exists: $rgName"
            }
# Storage Account
    #remove #$stAcct = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -ErrorAction SilentlyContinue
            $stAcct = (Get-AzureRmStorageAccount | ?{$_.StorageAccountName -eq "$saName"})
            if ($stAcct -eq $null) {
                Write-Output "creating storage account: $saName..."
                $stAcct = New-AzureRmStorageAccount -ResourceGroupName $rgstore -Name $saName -SkuName Standard_LRS -Kind Storage -Location $Location -ErrorAction SilentlyContinue
            }
            else {
                Write-Output "storage account already exists: $saName"
            }
            if ($stAcct -ne $null) {
                $stURI = $stAcct.PrimaryEndpoints.Blob.ToString()
                Write-Output "storage account URI: $stURI"
            }
# Virtual Network
           if ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$subnetName"}){
               Write-Output "subnet already exists: $subnetName"
               $subnet = ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$subnet"})
           } 
           else {
            Write-Output "creating virtual network subnet: $subnetName / $subnetPfx..."
            $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPfx
           }

            #$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            $vnet = (Get-AzureRmVirtualNetwork | ?{$_.Name -eq "$vnetName"})
            if ($vnet -ne $null) {
                Write-Output "virtual network already exists: $vnetName"
            }
            else {
                Write-Output "creating virtual network: $vnetName in $Location..."
                $vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgnet -Location $Location -AddressPrefix $addressPfx -Subnet $subnet
            }
# Public IP Address Creation
            Write-Output "creating public IP: $ipName..."
            $pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $Location -AllocationMethod Dynamic
# NIC Creation
            Write-Output "creating NIC: $nicName..."
            $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $Location -SubnetId $subnet.id -PublicIpAddressId $pip.Id -PrivateIpAddress $privIP
# VM components
            Write-Output "preparing components for virtual machine..."
			$SecurePassword = ConvertTo-SecureString "answer2830" -AsPlainText -Force
			$Credential = New-Object System.Management.Automation.PSCredential ("kevin", $SecurePassword); 
            $vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
            $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmname -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
# Remove    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus $vmOS -Version "latest"
            $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
# VM Disk (OS)
            $imageUri  = "$stURI"+"$sourceCont"+"/$sourceVHD"
            $osDiskUri = "$stURI"+"$destCont"+"/$osdiskname"
            Write-Output "disk blob uri is $osDiskUri"
            $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption FromImage -SourceImageUri $imageUri -Windows
# VM Creation
            Write-Output "creating virtual machine: $vmName..."
            New-AzureRmVM -ResourceGroupName $rgName -Location $Location -VM $vm
# Write Results to Screen
            $vmNic = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName
            $pvtIP = $($vmNic.IpConfigurations).PrivateIpAddress
            $pubIP = $(Get-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgname).IpAddress
            Write-Output "`tPrivate IP: $pvtIP"
            Write-Output "`tPublic IP: $pubIP"
        }
        else {
            Write-Output "testmode enabled."
            Write-Output "vm: $vmName / size: $vmSize / Location: $Location"
            $blobPath  = "$vmName"+"os.vhd"
            $osDiskUri = "$stURI"+"vhds/$blobPath"
            $diskName  = "$vmName"+"osdisk"
            Write-Output "`tstorage blob: $osDiskUri"
            Write-Output "`tstorage disk: $diskName"
        }
    }
}

Write-Output "Finished!!!"

# Remove-AzureRmResourceGroup -Name $rgName -Force