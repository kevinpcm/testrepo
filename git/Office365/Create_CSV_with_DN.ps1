<# 
This script expects a CSV named BHFUsers.csv with the column header primarysmtpaddress
It will Export another CSV name BHFUsersDN.csv to be used with Get_365_Folder_Perms.ps1
#>
$TheCSV = Import-Csv ./BHFusers.csv -Header primarysmtpaddress
foreach ($row in $TheCSV)
    {
    Get-Mailbox -ResultSize unlimited $row.primarysmtpaddress | select primarysmtpaddress,distinguishedname,identity | Export-csv ./BHFUsersDN.csv -NTI -Append
    }