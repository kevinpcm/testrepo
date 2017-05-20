Get-Content 'C:\scripts\Batch13_Remaining_34.txt' | % {
    $row = $_ | Get-MoveRequest  
    $_ | Add-Member -MemberType ScriptProperty -Name UPN -Value {$_}
    $_ | Add-Member -MemberType ScriptProperty -Name Sts -Value {$row.Status}
    $_ | Select UPN, Sts
} 