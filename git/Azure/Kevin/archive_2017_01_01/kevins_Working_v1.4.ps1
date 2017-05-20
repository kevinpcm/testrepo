
param (
    [parameter(Mandatory=$False)] [string] $InputFile  = "godc.csv"
      )

Login-AzureRmAccount
Save-AzureRmProfile -Path .\profile1.json -Force
Select-AzureRmProfile -Path .\profile1.json
Write-Output "reading input file: $InputFile..."
$csvData = Import-Csv $InputFile
if ($csvData -ne $null) {

    foreach ($row in $csvData) {
        $Location      = $row.Location
        $vnetName      = $row.vnetName
		$saName        = $row.StorageAccount
        $rgName        = $row.ResourceGroup
        $rgstore       = $row.StorageResGroup
        $rgnet         = $row.NetworkingResGroup
        $subnetName    = $row.SubnetName        
        # Resource Group
        $rg = Get-AzureRmResourceGroup -Name $rgName -Location $Location -ErrorAction SilentlyContinue
        if ($rg -eq $null) 
        {
            Write-Output "creating resource group: $rgName..."
            $rg = New-AzureRmResourceGroup -Name $rgName -Location $Location
        }
        else 
        {
            Write-Output "resource group already exists: $rgName"
        }
        
        # Resource Group Storage
        $rgs = Get-AzureRmResourceGroup -Name $rgstore -Location $Location -ErrorAction SilentlyContinue
        if ($rgs -eq $null) 
        {
            Write-Output "creating resource group: $rgstore..."
            $rgs = New-AzureRmResourceGroup -Name $rgstore -Location $Location
        }
        else 
        {
            Write-Output "resource group already exists: $rgstore"
        }
        
        # Resource Group Network
        $rgn = Get-AzureRmResourceGroup -Name $rgnet -Location $Location -ErrorAction SilentlyContinue
        if ($rgn -eq $null) 
        {
            Write-Output "creating resource group: $rgnet..."
            $rgn = New-AzureRmResourceGroup -Name $rgnet -Location $Location
        }
        else 
        {
            Write-Output "resource group already exists: $rgnet"
        }
        
        # Storage Account   
        $stAcct = (Get-AzureRmStorageAccount | ?{$_.StorageAccountName -eq "$saName"})
        if ($stAcct -eq $null) 
        {
            Write-Output "creating storage account: $saName..."
            $stAcct = New-AzureRmStorageAccount -ResourceGroupName $rgstore -Name $saName -SkuName Standard_LRS -Kind Storage -Location $Location #-ErrorAction SilentlyContinue
        }
        else 
        {
            Write-Output "storage account already exists: $saName"
        }
        if ($stAcct -ne $null) 
        {
            $stURI = $stAcct.PrimaryEndpoints.Blob.ToString()
            Write-Output "storage account URI: $stURI"
        }
        
        # Virtual Network
        # Subnet
        if ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$subnetName"})
        {
            Write-Output "subnet already exists: $subnetName"
            $subnet = ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$subnetName"}).Id
        } 
        else 
        {
            Write-Output "creating virtual network subnet: $subnetName / $subnetPfx..."
            $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPfx
        }
        
        # VNet
        $vnet = (Get-AzureRmVirtualNetwork | ?{$_.Name -eq "$vnetName"})
        if ($vnet -ne $null) 
        {
            Write-Output "virtual network already exists: $vnetName"
        }
        else 
        {
            Write-Output "creating virtual network: $vnetName in $Location..."
            $vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgnet -Location $Location -AddressPrefix $addressPfx -Subnet $subnet
        }       
    
    } #first foreach
    foreach ($row in $csvData) {
        $Location      = $row.Location
		$vmName        = $row.Name
        $sourceCont    = $row.sourceContainer
        $sourceVHD     = $row.SourceVHD
        $destCont      = $row.destinationContainer
		$osDiskUri     = $row.osdiskUri
		$saName        = $row.StorageAccount
        $vmSize        = $row.Size
        $privIP        = $row.PrivateIP
        $vnetName      = $row.vnetName
        $subnetName    = $row.SubnetName
        $subnetPfx     = $row.SubnetRange
        $addressPfx    = $row.AddressRange
        $rgName        = $row.ResourceGroup
        $rgstore       = $row.StorageResGroup
        $rgnet         = $row.NetworkingResGroup
        $caching       = $row.caching
        $DataDiskSize1 = $row.DataDiskSize1
        $nicName       = "$vmName"+"nic1"
        $osdiskname    = "$vmName"+"os.vhd"
        $diskName      = "$vmName"+"osdisk"
        $datadiskname  = "$vmName"+"datadisk.vhd"
        $ipName        = "$vmName"+"pip1"
       

            $ScriptBlock =
            {
            $uuLocation		=$using:Location
            $uuvmName		=$using:vmName
            $uusourceCont	=$using:sourceCont
            $uusourceVHD	=$using:sourceVHD
            $uudestCont		=$using:destCont
            $uuosDiskUri	=$using:osDiskUri
            $uusaName		=$using:saName
            $uuvmSize		=$using:vmSize
            $uuprivIP		=$using:privIP
            $uuvnetName		=$using:vnetName
            $uusubnetName	=$using:subnetName
            $uusubnetPfx	=$using:subnetPfx
            $uuaddressPfx	=$using:addressPfx
            $uurgName		=$using:rgName
            $uurgstore		=$using:rgstore
            $uurgnet		=$using:rgnet
            $uucaching		=$using:caching
            $uuDataDiskSize1=$using:DataDiskSize1
            $uunicName		=$using:nicName
            $uuosdiskname	=$using:osdiskname
            $uudiskName		=$using:diskName
            $uudatadiskname	=$using:datadiskname
            $uuipName		=$using:ipName
                    
                    Select-AzureRmProfile -Path .\profile1.json
                    
                    # Resource Group
                    $rg = Get-AzureRmResourceGroup -Name $uurgName -Location $uuLocation -ErrorAction SilentlyContinue
                    if ($rg -eq $null)  
                    {
                        Write-Output "creating resource group: $uurgName..."
                        $rg = New-AzureRmResourceGroup -Name $uurgName -Location $uuLocation
                    }
                    else 
                    {
                        Write-Output "resource group already exists: $uurgName"
                    }
                    
                    # Resource Group Storage
                    $rgs = Get-AzureRmResourceGroup -Name $uurgstore -Location $uuLocation -ErrorAction SilentlyContinue
                    if ($rgs -eq $null) 
                    {
                        Write-Output "creating resource group: $uurgstore..."
                        $rgs = New-AzureRmResourceGroup -Name $uurgstore -Location $uuLocation
                    }
                    else 
                    {
                        Write-Output "resource group already exists: $uurgstore"
                    }
                    
                    # Resource Group Network
                    $rgn = Get-AzureRmResourceGroup -Name $uurgnet -Location $uuLocation -ErrorAction SilentlyContinue
                    if ($rgn -eq $null) 
                    {
                        Write-Output "creating resource group: $uurgnet..."
                        $rgn = New-AzureRmResourceGroup -Name $uurgnet -Location $uuLocation
                    }
                    else 
                    {
                        Write-Output "resource group already exists: $uurgnet"
                    }
                    
                    # Storage Account
                    $stAcct = (Get-AzureRmStorageAccount | ?{$_.StorageAccountName -eq "$uusaName"})
                    if ($stAcct -eq $null) 
                    {
                        Write-Output "creating storage account: $uusaName..."
                        $stAcct = New-AzureRmStorageAccount -ResourceGroupName $uurgstore -Name $uusaName -SkuName Standard_LRS -Kind Storage -Location $uuLocation #-ErrorAction SilentlyContinue
                    }
                    else 
                    {
                        Write-Output "storage account already exists: $uusaName"
                    }
                    if ($stAcct -ne $null) 
                    {
                        $stURI = $stAcct.PrimaryEndpoints.Blob.ToString()
                        Write-Output "storage account URI: $stURI"
                    }
                    
                    # Virtual Network
                    # Subnet
                    if ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$uusubnetName"})
                    {
                            Write-Output "subnet already exists: $uusubnetName"
                            $subnet = ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$uusubnetName"}).Id
                    } 
                    else 
                    {
                            Write-Output "creating virtual network subnet: $uusubnetName / $uusubnetPfx..."
                            $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $uusubnetName -AddressPrefix $uusubnetPfx
                    }
                    # VNet
                    $vnet = (Get-AzureRmVirtualNetwork | ?{$_.Name -eq "$uuvnetName"})
                    if ($vnet -ne $null) 
                    {
                        Write-Output "virtual network already exists: $uuvnetName"
                    }
                    else 
                    {
                        Write-Output "creating virtual network: $uuvnetName in $uuLocation..."
                        $vnet = New-AzureRmVirtualNetwork -Name $uuvnetName -ResourceGroupName $uurgnet -Location $uuLocation -AddressPrefix $uuaddressPfx -Subnet $subnet
                    }
                    
                    # Public IP Address Creation
                    Write-Output "creating public IP: $uuipName..."
                    $pip = New-AzureRmPublicIpAddress -Name $uuipName -ResourceGroupName $uurgName -Location $uuLocation -AllocationMethod Static -Force
                    
                    # NIC Creation
                    Write-Output "creating NIC: $uunicName..."
                    $nic = New-AzureRmNetworkInterface -Name $uunicName -ResourceGroupName $uurgName -Location $uuLocation -SubnetId $subnet -PublicIpAddressId $pip.Id -PrivateIpAddress $uuprivIP -Force
                    
                    # VM components
                    Write-Output "preparing components for virtual machine..."
                    $SecurePassword = ConvertTo-SecureString "Answer2830" -AsPlainText -Force
                    $Credential = New-Object System.Management.Automation.PSCredential ("install", $SecurePassword); 
                    $vm = New-AzureRmVMConfig -VMName $uuvmName -VMSize $uuvmsize
                    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $uuvmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
                    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
                    
                    # VM Disk (OS)
                    $imageUri    = "$stURI"+"$uusourceCont"+"/$uusourceVHD"
                    $uuosDiskUri   = "$stURI"+"$uudestCont"+"/$uuosdiskname"
                    $dataDiskUri = "$stURI"+"$uudestCont"+"/$uudatadiskname"
                    Write-Output "disk blob uri is $uuosDiskUri"
                    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $uudiskName -VhdUri $uuosDiskUri -CreateOption FromImage -SourceImageUri $imageUri -Windows
                    
                    # VM Creation
                    Write-Output "creating virtual machine: $uuvmName..."
                    New-AzureRmVM -ResourceGroupName $uurgName -Location $uuLocation -VM $vm
                    
                    # VM Disk (DATA)
                    if ($uudatadiskname -ne "") 
                    {
                        Write-Output "Creatung Data Disk: $uudatadiskname"     
                        $vm = Get-AzureRmVM -ResourceGroupName $uurgName -Name $uuvmName 
                        Add-AzureRmVMDataDisk -VM $vm -Name $uudatadiskname -VhdUri $dataDiskUri -Caching $uucaching -DiskSizeinGB $uuDataDiskSize1  -CreateOption Empty
                        Update-AzureRmVM -ResourceGroupName $uurgName -VM $vm
                    }
                    # Write Results to Screen
                    $vmNic = Get-AzureRmNetworkInterface -Name $uunicName -ResourceGroupName $uurgName
                    $pvtIP = $($vmNic.IpConfigurations).PrivateIpAddress
                    $pubIP = $(Get-AzureRmPublicIpAddress -Name $uuipName -ResourceGroupName $uurgName).IpAddress
                    Write-Output "`tPrivate IP: $pvtIP"
                    Write-Output "`tPublic IP: $pubIP"
                
            }
        Write-Output "vmname: $vmName"
        Start-Job -scriptblock $ScriptBlock # -Name $vmName -Verbose
        Write-Output "Finished!!!"
    } #second foreach
} #if csvData -ne $null - maybe remove? 
        Get-Job | Receive-Job

function WaitforAllRunning($vmName)
        {
        do  {
            Start-Sleep -milliseconds 100
            $vmStatuses  = Get-AzureRmVM -VM $vmName -ResourceGroupName $rgName -Status | select -ExpandProperty Statuses | Select -ExpandProperty DisplayStatus
            $vmStatus0   = $VMStatuses[0]
            $vmStatus1   = $VMStatuses[1]
            $vmStatusC   = Get-AzureRmVM -VM $vmName -ResourceGroupName $rgName -Status | select -ExpandProperty Statuses | Select -ExpandProperty Code
            $vmCode      = $vmStatusC[0]
            } 
            until ({$vmStatus0 -eq 'Provisioning succeeded'} -and {$vmStatus1 -eq 'VM running'} -and {$vmCode = 'ProvisioningState/succeeded'})
                
        }
foreach ($row in $csvData)
    {
    $vmName  = $row.name
    $rgName  = $row.ResourceGroup    
    Write-Output "Azure VM: $vmName"
    WaitforAllRunning -vm $vmName
    }
Write-Output "ADD DSC FUNCTION CALL HERE"