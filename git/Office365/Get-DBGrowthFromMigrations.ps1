$MBXPath = "C:\scripts\SomeMailboxes.txt"
$DBPath = "C:\scripts\DBs.txt"

ForEach ($DB in  Get-Content -Path $DBPath) {
    [float] $size = 0.0
    $dbid = (Get-MailboxDatabase $DB).Identitiy
    ForEach ($mbx in Get-Content -Path $MbxPath) {
          $size += (Get-MailboxStatistics $mbx -Database $dbid -EA SilentlyContinue).totalItemSize.Value.ToBytes() / 1GB
    }
    Write-Output "DB $DB size is approximately $([math]::Round($size , 2)) GB"
}