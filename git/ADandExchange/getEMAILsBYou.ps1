$csvData = Import-Csv ou.csv
$a = @()
foreach ($row in $csvData) {  
    $OU   = $row.ou

$a += (Get-ADUser -SearchBase $ou -filter * -properties Displayname, EmailAddress | Select DisplayName,EmailAddress,distinguishedname,userprincipalname)

}
$a | Export-Csv C:\scripts\ouEMAIL4.csv -notypeinformation