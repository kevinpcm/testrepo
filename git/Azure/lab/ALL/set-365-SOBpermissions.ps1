$in = import-csv "C:\scripts\365PermissionExport.txt"
foreach ($row in $in)
    {
        
        $test = Get-Mailbox $row.alias
        $sob2 = $row.sendonbehalf -split " "
        Write-Output "TEST: $test"
        Write-Output "SOB2: $sob2"
        foreach ($r in $sob2)
        {
            Write-Output "R: $r"
            Set-mailbox $row.alias -grantsendonbehalfto @{Add= $r} -verbose
        }
        Write-Output $test
    }