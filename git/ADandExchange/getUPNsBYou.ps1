$csvData = Import-Csv ou.csv

foreach ($row in $csvData) {  
    $OU   = $row.ou
$a += (Get-ADUser -SearchBase $ou -filter * | Select distinguishedname,userprincipalname)

}
$b = $a | Export-Csv C:\scripts\ou12.csv
 
