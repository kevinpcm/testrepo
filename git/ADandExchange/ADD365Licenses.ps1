#Bulk E3 License Assignment with no Services disabled
$AccountSkuId = "kslcapital:ENTERPRISEPACK"
$UsageLocation = "US"
$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $AccountSkuId

$Users = Import-Csv c:\scripts\BATCH3.csv
$Users | ForEach-Object {
Set-MsolUser -UserPrincipalName $_.emailaddress -UsageLocation $UsageLocation
Set-MsolUserLicense -UserPrincipalName $_.emailaddress -LicenseOptions $LicenseOptions
}
