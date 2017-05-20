function Get-Blob {
    [CmdletBinding()]

    param(
    [Parameter(ValueFromPipelineByPropertyName=$true)][String]$ResourceGroupName,
    [Parameter(ValueFromPipelineByPropertyName=$true)][String]$StorageAccountName
    )
Process {

$blobs = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName | Get-AzureStorageBlob -Container vhd | ? {$_.name -match "data"}
$Results = @()
$blobs | ForEach {
            $PSObject = New-Object PSObject
            $PSObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value $_.name
            $PSObject | Add-Member -MemberType NoteProperty -Name 'Size (GB)' -Value ([math]::Round($_.Length/ 1GB))            
            $Results += $PSObject
        }

Return $Results
}
        }