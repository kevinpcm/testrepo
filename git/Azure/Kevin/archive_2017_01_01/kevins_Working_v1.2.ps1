
param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "kevin@thenext.net",
    [parameter(Mandatory=$False)] [string] $azTenId    = "ffefc0c4-2ef8-49f8-a251-907971968a26",
    [parameter(Mandatory=$False)] [string] $azSubId    = "d2fc1b6f-162c-4553-b423-6c8b9902819e",
    [parameter(Mandatory=$False)] [string] $InputFile  = "godc.csv"
)

Write-Output "checking if session is authenticated..."
if ($azCred -eq $null) {
    Write-Output "authentication is required."
    $azCred = Login-AzureRmAccount -SubscriptionId $azSubId -Tenant $azTenId
}
else {
    Write-Output "authentication already confirmed."
}

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
        if ($rg -eq $null) {
            Write-Output "creating resource group: $rgName..."
            $rg = New-AzureRmResourceGroup -Name $rgName -Location $Location
        }
        else {
            Write-Output "resource group already exists: $rgName"
        }
# Resource Group Storage
        $rgs = Get-AzureRmResourceGroup -Name $rgstore -Location $Location -ErrorAction SilentlyContinue
        if ($rgs -eq $null) {
            Write-Output "creating resource group: $rgstore..."
            $rgs = New-AzureRmResourceGroup -Name $rgstore -Location $Location
        }
        else {
            Write-Output "resource group already exists: $rgstore"
        }
# Resource Group Network
        $rgn = Get-AzureRmResourceGroup -Name $rgnet -Location $Location -ErrorAction SilentlyContinue
        if ($rgn -eq $null) {
            Write-Output "creating resource group: $rgnet..."
            $rgn = New-AzureRmResourceGroup -Name $rgnet -Location $Location
        }
        else {
            Write-Output "resource group already exists: $rgnet"
        }
# Storage Account
        $stAcct = (Get-AzureRmStorageAccount | ?{$_.StorageAccountName -eq "$saName"})
        if ($stAcct -eq $null) {
            Write-Output "creating storage account: $saName..."
            $stAcct = New-AzureRmStorageAccount -ResourceGroupName $rgstore -Name $saName -SkuName Standard_LRS -Kind Storage -Location $Location #-ErrorAction SilentlyContinue
        }
        else {
            Write-Output "storage account already exists: $saName"
        }
        if ($stAcct -ne $null) {
            $stURI = $stAcct.PrimaryEndpoints.Blob.ToString()
            Write-Output "storage account URI: $stURI"
        }
# Virtual Network
  # Subnet
        if ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$subnetName"}){
            Write-Output "subnet already exists: $subnetName"
            $subnet = ((Get-AzureRmVirtualNetwork).Subnets | ?{$_.Name -eq "$subnetName"}).Id
        } 
        else {
            Write-Output "creating virtual network subnet: $subnetName / $subnetPfx..."
            $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPfx
        }
  # VNet
        $vnet = (Get-AzureRmVirtualNetwork | ?{$_.Name -eq "$vnetName"})
        if ($vnet -ne $null) {
            Write-Output "virtual network already exists: $vnetName"
        }
        else {
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
       
        if ($vmName.Substring(0,1) -ne ";") {
<#           $ScriptBlock =
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
            C:\scripts\git\Azure\Kevin\sb.ps1
            } 
#>
        } # end if
        Write-Output "vmname: $vmName" 
        Start-Job -scriptblock {'C:\scripts\git\Azure\Kevin\sb.ps1'} # -JobName $vmName 
        Write-Output "Finished!!!"
    } #second foreach

 
}