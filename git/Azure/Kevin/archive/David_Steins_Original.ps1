# referenced: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-ps-create/

param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "<<YOUR_ID>>",
    [parameter(Mandatory=$False)] [string] $azTenId    = "<<YOUR_TENANT_ID>>",
    [parameter(Mandatory=$False)] [string] $azSubId    = "<<YOUR_SUBSCRIPTION_ID>>",
    [parameter(Mandatory=$False)] [string] $InputFile  = "azurelab.csv",
    [parameter(Mandatory=$False)] [string] $saName     = "dsstacct1",
    [parameter(Mandatory=$False)] [string] $Location   = "eastus",
    [parameter(Mandatory=$False)] [string] $subnetName = "dssubnet1",
    [parameter(Mandatory=$False)] [string] $vnetName   = "vnetds1"
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
    if ($LocalUser -eq $null) {
        Write-Output "setting credentials for local administrator account..."
        $LocalUser = Get-Credential -Message "Type the name and password of the local administrator account."
    }

    foreach ($row in $csvData) {
        $vmName     = $row.Name
        $rgName     = $row.ResourceGroup
        $vmOS       = $row.OS
        $vmSize     = $row.Size
        $vmSNName   = $row.SubnetName
        $subnetPfx  = $row.SubnetRange
        $addressPfx = $row.AddressRange
        $nicName    = "$vmName"+"nic1"
        $blobPath   = "$vmName"+"os.vhd"
        $diskName   = "$vmName"+"osdisk"
        $ipName     = "$vmName"+"pip1"

        if ($vmName.Substring(0,1) -ne ";") {

            $rg = Get-AzureRmResourceGroup -Name $rgName -Location $Location -ErrorAction SilentlyContinue
            if ($rg -eq $null) {
                Write-Output "creating resource group: $rgName..."
                $rg = New-AzureRmResourceGroup -Name $rgName -Location $Location
            }
            else {
                Write-Output "resource group already exists: $rgName"
            }

            $stAcct = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -ErrorAction SilentlyContinue
            if ($stAcct -eq $null) {
                Write-Output "creating storage account: $saName..."
                $stAcct = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -SkuName Standard_LRS -Kind Storage -Location $Location -ErrorAction SilentlyContinue
            }
            else {
                Write-Output "storage account already exists: $saName"
            }
            if ($stAcct -ne $null) {
                $stURI = $stAcct.PrimaryEndpoints.Blob.ToString()
                Write-Output "storage account URI: $stURI"
            }

            Write-Output "creating virtual network subnet: $subnetName / $subnetPfx..."
            $singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPfx

            $vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if ($vnet -ne $null) {
                Write-Output "virtual network already exists: $vnetName"
            }
            else {
                Write-Output "creating virtual network: $vnetName in $Location..."
                $vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $Location -AddressPrefix $addressPfx -Subnet $singleSubnet
            }

            Write-Output "creating public IP: $ipName..."
            $pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $Location -AllocationMethod Dynamic

            Write-Output "creating NIC: $nicName..."
            $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

            Write-Output "preparing components for virtual machine..."

            $vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
            $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmname -Credential $LocalUser -ProvisionVMAgent -EnableAutoUpdate
            $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus $vmOS -Version "latest"
            $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

            $osDiskUri = "$stURI"+"vhds/$blobPath"
            Write-Output "disk blob uri is $osDiskUri"
            $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption FromImage

            Write-Output "creating virtual machine: $vmName..."
            New-AzureRmVM -ResourceGroupName $rgName -Location $Location -VM $vm

            $vmNic = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName
            $pvtIP = $($vmNic.IpConfigurations).PrivateIpAddress
            $pubIP = $(Get-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgname).IpAddress
            Write-Output "`tPrivate IP: $pvtIP"
            Write-Output "`tPublic IP: $pubIP"
        }
        else {
            Write-Output "testmode enabled."
            Write-Output "vm: $vmName / size: $vmSize / os: $vmOS / Location: $Location"
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