# Input Files
$LicTheseUsersPath = '.\LicUsers2.txt'
$LicenseTheseUsers = Get-Content $LicTheseUsersPath
$CurrentlyLicensed = Get-MsolUser -All | ? {$_.IsLicensed -eq 'True'}

# Build List by Comparison
ForEach ($row in $CurrentlyLicensed | Where {$LicenseTheseUsers -notcontains $_.UserPrincipalName}) {
    Write-Output $row.UserPrincipalName
}