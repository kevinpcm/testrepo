$in = import-csv "C:\scripts\365PermissionExport.txt"
foreach ($row in $in)
    {
        $test = Get-Mailbox $row.alias
        $sob2 = $row.fullaccess -split " "
        foreach ($r in $sob2)
        {
            Add-MailboxPermission -AccessRights fullaccess -Identity $row.alias -User $r
        }
    }