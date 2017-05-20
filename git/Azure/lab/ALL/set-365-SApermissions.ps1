$in = import-csv "C:\scripts\365PermissionExport.txt"
foreach ($row in $in)
    {
        $test = Get-Mailbox $row.alias
        $sob2 = $row.sendas -split " "
        foreach ($r in $sob2)
        {
            Add-RecipientPermission -Identity $row.alias -AccessRights SendAs -Trustee $r -confirm:$false
        }
    }