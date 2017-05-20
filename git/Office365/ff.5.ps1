$MbxPath = "C:\scripts\Rollback.txt"
$DBPath = "C:\scripts\DBs.txt"
Get-Content -Path $DBPath | foreach {
    $DB = $_
    Write-Output "DB: $DB"
    Get-Content -Path $MbxPath | foreach { 
        $MBX = $_
        Write-Output "MBX: $MBX"
        Get-Mailbox $MBX | ? {$_.name -eq $DB} | Get-MailboxStatistics |
            select-object @{l = "dbase"; e = {$_.database}}, @{l = "size"; e = {$_.TotalItemSize.Value.ToMB()}} | Measure-Object -sum size }
}