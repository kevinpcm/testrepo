$blobs = Get-AzureRmStorageAccount -Name "ivantagestorage01" -ResourceGroupName "core-storage" | Get-AzureStorageBlob -Container vhd | ? {$_.name -match "data"}
$Results = @()
$blobs | ForEach {
            $PSObject = New-Object PSObject
            $PSObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value $_.name
            $PSObject | Add-Member -MemberType NoteProperty -Name 'Size (GB)' -Value ([math]::Round($_.Length/ 1GB))            
            $Results += $PSObject
        }

$Results | Export-Csv "C:\scripts\blobs17.csv" -NoTypeInformation
