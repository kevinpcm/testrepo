$MBXPath = "C:\scripts\RollbackTEST.txt"
$MBXcontent = Get-Content -Path $MbxPath
$DBPath = "C:\scripts\DBs.txt"
$DBcontent = Get-Content -Path $DBPath 

ForEach ($DB in $DBcontent) {
    $MBXcontent    | foreach { 
        $Stats = Get-Mailbox $_ | ? {$_.Database -like $DB} | Get-MailboxStatistics 
        $_ | Add-Member -MemberType ScriptProperty -Name "TIS" -Value {
            ($stats | foreach {$_.totalItemSize.Value.ToBytes()}| Measure -sum).sum/1MB }
    }  
    select-object $DB, TIS 
}