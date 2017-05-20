
# Start Transcript of PowerShell Session
Start-Transcript -Path '.\HDS_UNLICENSE_BATCH01.txt' -Append

# Define Arrays
$BaseDisabled = @()

# Assign Tenant and Location to a variable
$Tenant = "hitachidatasystems"
$Location = "US"
        
# Assign each AccountSkuID to a variable
$SkuE5 = ($Tenant + ':ENTERPRISEPREMIUM')
$SkuE4 = ($Tenant + ':ENTERPRISEWITHSCAL')
$SkuE3 = ($Tenant + ':ENTERPRISEPACK')
$SkuE2 = ($Tenant + ':STANDARDWOFFPACK')
$SkuE1 = ($Tenant + ':STANDARDPACK')
$SkuEO2 = ($Tenant + ':EXCHANGEENTERPRISE')
$SkuEMS = ($Tenant + ':EMS')
$SkuShareEnt = ($Tenant + ':SHAREPOINTENTERPRISE')        
$SkuPowerApps = ($Tenant + ':POWERAPPS_INDIVIDUAL_USER')
$SkuPowerBI = ($Tenant + ':POWER_BI_INDIVIDUAL_USER')        
$SkuPowerBIPro = ($Tenant + ':POWER_BI_PRO')
$SkuPowerBIFree = ($Tenant + ':POWER_BI_STANDARD')        
$SkuRMSAdhoc = ($Tenant + ':RIGHTSMANAGEMENT_ADHOC')
$SkuATP = ($Tenant + ':ATP_ENTERPRISE')
        
# Set Base Disabled Options for E4    
$BaseDisabled = 'Deskless', 'FLOW_O365_P2', 'POWERAPPS_O365_P2', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY', 'INTUNE_O365', 'YAMMER_ENTERPRISE', 'RMS_S_ENTERPRISE', 'MCOVOICECONF', 'MCOSTANDARD', 'SHAREPOINTWAC', 'SHAREPOINTENTERPRISE'

# Set SKUs to be removed
$SKUstobeRemoved = @()
$SKUstobeRemoved += , $SkuATP
$SKUstobeRemoved += , $SkuE4

# Input Files
#$UNLicTheseUsersPath = '.\ShouldBeUnlicensed.csv'
$UNLicTheseUsersPath = '.\Unlicense_Round2_All_Licensed_in_Cloud_BUT_NOT_on_Steves_List.csv'
$unlicense = Get-Content $UNLicTheseUsersPath

# Error Log
$Outfile = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-unlicense-log.txt")

#Define HeaderString
Out-File -FilePath $OutFile -InputObject "UPN,Results" -Encoding utf8

$users = foreach ($user in $unlicense) { 
    Get-MsolUser -UserPrincipalName $user 
}

# Remove All Skus
ForEach ($sku in $SKUstobeRemoved) {
    ForEach ($row in $users) {
        if ($row.licenses.accountskuid -notcontains $SKU) {
            Write-Output "$($row.userprincipalname) does not have $($SKU) no need to remove"
        } 
        else {
            Write-Output "$($row.userprincipalname) has $($SKU) REMOVING NOW"
            Set-MsolUserLicense -UserPrincipalName $row.userprincipalname -RemoveLicenses $sku -Verbose -ErrorAction Continue
        }
        $Report = "$($row.userprincipalname),$sku"
        Out-File -FilePath $OutFile -InputObject $Report -Append -Encoding utf8
    }
}