$NewSku = New-MsolLicenseOptions -AccountSkuId "sentara99:ENTERPRISEPREMIUM" # -DisabledPlans FLOW_O365_P1,POWERAPPS_O365_P1,TEAMS1,PROJECTWORKMANAGEMENT,SWAY,MCOSTANDARD,SHAREPOINTSTANDARD,SHAREPOINTWAC,YAMMER_MIDSIZE
$AccountSkuId = "sentara99:ENTERPRISEPREMIUM"
$UsageLocation = "US"
$Users = Import-Csv licenseme.csv
$Users | ForEach-Object {
Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $UsageLocation
Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses $AccountSkuId -LicenseOptions $NewSku
}