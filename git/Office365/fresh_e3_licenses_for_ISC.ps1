$NewSku = New-MsolLicenseOptions -AccountSkuId "sent:ENTERPRISEPACK"
$AccountSkuId = "sent:ENTERPRISEPACK"
$UsageLocation = "US"
$Users = Import-Csv ISC.csv
$Users | ForEach-Object {
Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $UsageLocation
Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses $AccountSkuId -LicenseOptions $NewSku
}