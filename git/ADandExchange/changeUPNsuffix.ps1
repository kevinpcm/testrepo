#Replace with the old suffix
$oldSuffix = 'ksldenver.local'

#Replace with the new suffix
$newSuffix = 'kslcapital.com'

#Replace with the OU you want to change suffixes for
# $ou = "DC=sample,DC=domain"

#Replace with the name of your AD server
$server = "KSLDC1"

$csvData = Import-Csv ou.csv

foreach ($row in $csvData) { 
    $OU   = $row.ou
Get-ADUser -SearchBase $ou -filter * | ForEach-Object {
$newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
$_ | Set-ADUser -server $server -UserPrincipalName $newUpn
}
    }