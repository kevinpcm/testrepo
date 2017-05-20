
$TheCSV = Import-Csv ./metlife.csv
foreach ($row in $TheCSV)
    {
    Get-Mailbox $row.mail | select displayname, primarysmtpaddress, alias | Export-csv ./metlifeWithAlias.csv -NTI -Append
    }