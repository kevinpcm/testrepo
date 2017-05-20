$LicTheseUsersPath = '.\LicenseUserlist.csv'
$LicenseTheseUsers = Get-Content $LicTheseUsersPath

foreach ($row in $LicenseTheseUsers){
    Get-MsolUser -UserPrincipalName $row |? {$_.UsageLocation -eq '$null'} | Select UserPrincipalName, UsageLocation
}