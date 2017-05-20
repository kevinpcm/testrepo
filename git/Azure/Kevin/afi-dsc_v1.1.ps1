
param (
    [parameter(Mandatory=$False)] [string] $InputFile  = "afi-csv_workgroup.csv"
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
        $dns1          = $row.dns1
        $dns2          = $row.dns2
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
            $uuLocation		= $using:Location
            $uuvmName		= $using:vmName
            $uusourceCont	= $using:sourceCont
            $uusourceVHD	= $using:sourceVHD
            $uudestCont		= $using:destCont
            $uuosDiskUri	= $using:osDiskUri
            $uusaName		= $using:saName
            $uuvmSize		= $using:vmSize
            $uuprivIP		= $using:privIP
            $uudns1         = $using:dns1
            $uudns2         = $using:dns2            
            $uuvnetName		= $using:vnetName
            $uusubnetName	= $using:subnetName
            $uusubnetPfx	= $using:subnetPfx
            $uuaddressPfx	= $using:addressPfx
            $uurgName		= $using:rgName
            $uurgstore		= $using:rgstore
            $uurgnet		= $using:rgnet
            $uucaching		= $using:caching
            $uuDataDiskSize1= $using:DataDiskSize1
            $uunicName		= $using:nicName
            $uuosdiskname	= $using:osdiskname
            $uudiskName		= $using:diskName
            $uudatadiskname	= $using:datadiskname
            $uuipName		= $using:ipName
                    
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
                    $pip = New-AzureRmPublicIpAddress -Name $uuipName -ResourceGroupName $uurgName -Location $uuLocation -AllocationMethod Static
                    
                    # NIC Creation
                    Write-Output "creating NIC: $uunicName..."
                    $nic = New-AzureRmNetworkInterface -Name $uunicName -ResourceGroupName $uurgName -Location $uuLocation -SubnetId $subnet -PublicIpAddressId $pip.Id -PrivateIpAddress $uuprivIP
                    
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
                    if (($uuDataDiskSize1 -ne "") -and ($uucaching -ne ""))
                    {
                        Write-Output "Creating Data Disk: $uudatadiskname"     
                        $vm = Get-AzureRmVM -ResourceGroupName $uurgName -Name $uuvmName 
                        Add-AzureRmVMDataDisk -VM $vm -Name $uudatadiskname -VhdUri $dataDiskUri -Caching $uucaching -DiskSizeinGB $uuDataDiskSize1  -CreateOption Empty
                        Update-AzureRmVM -ResourceGroupName $uurgName -VM $vm
                    }
                    else 
                    {
                        Write-Output "No Data Disk will be created as either Data Disk Size and/or Caching Type was not specified"    
                    }
                    # Write Results to Screen
                    $vmNic = Get-AzureRmNetworkInterface -Name $uunicName -ResourceGroupName $uurgName
                    $pvtIP = $($vmNic.IpConfigurations).PrivateIpAddress
                    $pubIP = $(Get-AzureRmPublicIpAddress -Name $uuipName -ResourceGroupName $uurgName).IpAddress
                    Write-Output "`tPrivate IP: $pvtIP"
                    Write-Output "`tPublic IP: $pubIP"
                
            }
        Write-Output "vmname: $vmName"
        Start-Job -scriptblock $ScriptBlock -Name $vmName
        Write-Output "Finished!!!"
    } #second foreach
} #if csvData -ne $null
        Get-Job | ?{$_.State -ne 'completed'} | Receive-Job

Function WaitforAllRunning($vmName) {
	Do {
		Start-Sleep -MilliSeconds 1000
		If ($AzureRmVM = Get-AzureRmVM -VM $vmName -ResourceGroupName $rgName -Status -ErrorAction SilentlyContinue) {
			$vmStatuses  = $AzureRmVM | Select-Object -ExpandProperty Statuses | Select-Object -ExpandProperty DisplayStatus
			$vmStatus0   = $VMStatuses[0]
			$vmStatus1   = $VMStatuses[1]
			$vmStatusC   = $AzureRmVM | Select-Object -ExpandProperty Statuses | Select-Object -ExpandProperty Code
			$vmCode      = $vmStatusC[0]
		} Else {
			$vmStatus0 = $vmStatus1 = $vmStatusC = ''
		}
    } Until (($vmStatus0 -eq 'Provisioning succeeded') -and ($vmStatus1 -eq 'VM running') -and ($vmCode -eq 'ProvisioningState/succeeded'))
}
foreach ($row in $csvData)
    {
    $vmName  = $row.name
    $rgName  = $row.ResourceGroup    
    Write-Output "Waiting for this VM to be in a Running State: $vmName"
    WaitforAllRunning -vm $vmName
    }
# Function for Desired State Configuration (DSC)
function DSCTask
    {
    Get-PSSession | Remove-PSSession
    # Get-Job | where {$_.State -eq 'Completed'}| Remove-Job
    $securePass = ConvertTo-SecureString "Answer2830" -AsPlainText -force
    $local      = New-Object System.Management.Automation.PsCredential -ArgumentList ("localhost\install",$securePass)
    $domain     = New-Object System.Management.Automation.PsCredential -ArgumentList ("install@go.local",$securePass)
    $data       = import-csv $InputFile 
        ForEach ($row in $data) 
        {
        $func       = $row.function
        If ($func -eq 'IIS')
            {
            $vName       = $row.Name            
            $IP          = $row.PrivateIP
            $dns1        = $row.dns1
            $dns2        = $row.dns2            
            $jobname     = "JOB_DSC_IIS" + "$vName"
            New-PSSession -ComputerName $IP -Credential $local -Verbose 
            $TargetSess  = (Get-PSSession -ComputerName $IP -Credential $local  | where {$_.State -eq 'opened'})
            $destination = "c:\scripts\localhost.ps1"
            Copy-Item -Path .\afi-config-iis_v1.1.ps1 -Destination $destination -Force -ToSession $TargetSess
                $ScriptBlockIIS =
                {
                $domcred = $using:domain
                $uudns1  = $using:dns1
                $uudns2  = $using:dns2   
                cd "C:\scripts"; 
                .\localhost.ps1 -credential $local        
                }
            Invoke-Command -Session $TargetSess -scriptblock $ScriptBlockIIS -AsJob -JobName $jobname -Verbose
            }
        elseif ($func -eq 'SQL') 
            {
            $vName       = $row.Name            
            $IP          = $row.PrivateIP
            $dns1        = $row.dns1
            $dns2        = $row.dns2            
            $jobname     = "JOB_DSC_SQL" + "$vName"
            New-PSSession -ComputerName $IP -Credential $local -Verbose 
            $TargetSess  = (Get-PSSession -ComputerName $IP -Credential $local  | where {$_.State -eq 'opened'})
            $destination = "c:\scripts\localhost.ps1"
            Copy-Item -Path .\afi-config-sql_v1.1.ps1 -Destination $destination -Force -ToSession $TargetSess
                $ScriptBlockSQL =
                {
                $domcred = $using:domain
                $uudns1  = $using:dns1
                $uudns2  = $using:dns2   
                cd "C:\scripts"; 
                .\localhost.ps1 -credential $local        
                }
            Invoke-Command -Session $TargetSess -scriptblock $ScriptBlockSQL -AsJob -JobName $jobname -Verbose    
            }
        elseif ($func -eq 'DomJoin') 
            {
            $vName       = $row.Name            
            $IP          = $row.PrivateIP
            $dns1        = $row.dns1
            $dns2        = $row.dns2            
            $jobname     = "JOB_DSC_DomJoin" + "$vName"
            New-PSSession -ComputerName $IP -Credential $local -Verbose 
            $TargetSess  = (Get-PSSession -ComputerName $IP -Credential $local  | where {$_.State -eq 'opened'})
            $destination = "c:\scripts\localhost.ps1"
            Copy-Item -Path .\afi-config-domjoin_v1.1.ps1 -Destination $destination -Force -ToSession $TargetSess
                $ScriptBlockSQL =
                {
                $domcred = $using:domain
                $uudns1  = $using:dns1
                $uudns2  = $using:dns2   
                cd "C:\scripts"; 
                .\localhost.ps1 -credential $local        
                }
            Invoke-Command -Session $TargetSess -scriptblock $ScriptBlockSQL -AsJob -JobName $jobname -Verbose    
            }            
        elseif ($func -eq 'Workgrp') 
            {
            $vName       = $row.Name            
            $IP          = $row.PrivateIP
            $dns1        = $row.dns1
            $dns2        = $row.dns2            
            $jobname     = "JOB_DSC_DomJoin" + "$vName"
            New-PSSession -ComputerName $IP -Credential $local -Verbose 
            $TargetSess  = (Get-PSSession -ComputerName $IP -Credential $local  | where {$_.State -eq 'opened'})
            $destination = "c:\scripts\localhost.ps1"
            Copy-Item -Path .\afi-config-workgrp_v1.1.ps1 -Destination $destination -Force -ToSession $TargetSess
                $ScriptBlockSQL =
                {
                $domcred = $using:domain
                $uudns1  = $using:dns1
                $uudns2  = $using:dns2   
                cd "C:\scripts"; 
                .\localhost.ps1 -credential $local        
                }
            Invoke-Command -Session $TargetSess -scriptblock $ScriptBlockSQL -AsJob -JobName $jobname -Verbose    
            }                        
        }
    }
# Execute Function
DSCTask