
# Start Transcript of PowerShell Session
Start-Transcript -Path ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-ADDING-license-TRANSCRIPT.txt")

# Define Arrays
$BaseDisabled = @()

# Customer Specific Information
$Tenant = "hitachidatasystems"
$Location = "US"
$BaseDisabledE4 = 'Deskless', 'FLOW_O365_P2', 'POWERAPPS_O365_P2', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY', 'INTUNE_O365', 'YAMMER_ENTERPRISE', 'RMS_S_ENTERPRISE', 'MCOVOICECONF', 'MCOSTANDARD', 'SHAREPOINTWAC', 'SHAREPOINTENTERPRISE'
$BaseDisabledATP = $null
        
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
$BaseDisabled = @()
$BaseDisabled += , $BaseDisabledE4
$BaseDisabled += , $BaseDisabledATP

# Set SKUs to be removed
$SKUstobeAdded = @()
$SKUstobeAdded += , $SkuE4
$SKUstobeAdded += , $SkuATP

# Input Files
$LicTheseUsersPath = '.\License_Round_2.txt'
$License = Get-Content $LicTheseUsersPath

# Error Log
$Outfile = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-license-RESULTS-log.csv")
$ErrLog  = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-license-ERROR-log.csv")
$MsolLog = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-MSOL-ERROR-log.csv")

# Define HeaderString
Out-File -FilePath $OutFile -InputObject "UserPrincipalName,PriorStatus,SKU,Action" -Encoding utf8
Out-File -FilePath $ErrLog -InputObject "UPN,SKU,Results" -Encoding utf8
Out-File -FilePath $MsolLog -InputObject "UPN,Error" -Encoding utf8


# Loop through the list and get-msoluser for each
$users = foreach ($user in $License) { 
    Get-MsolUser -UserPrincipalName $user -ErrorAction Continue
}

# Remove from each user one SKU at a time
for ($i = 0; $i -lt $($SKUstobeAdded.Count); $i++) {
    ForEach ($user in $users) {
        if ($user.licenses.accountskuid -contains $SKUstobeAdded[$i]) {
            $Report = "$($user.userprincipalname),is already assigned SKU:,$($SKUstobeAdded[$i]),Modifying options if necessary"
            Out-File -FilePath $Outfile -InputObject $Report -Append -Encoding utf8
            Write-Output "$($user.userprincipalname)`;is already assigned SKU:`;$($SKUstobeAdded[$i])`;Modifying options if necessary"
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SKUstobeAdded[$i] -DisabledPlans $BaseDisabled[$i]
            $data = (Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction Continue) 2>&1
            if ($($Data.Exception.message)) {
                $ErrReport = "$($user.userprincipalname),$($SKUstobeAdded[$i]),$($Data.Exception.message)"
                Out-File -FilePath $ErrLog -InputObject $ErrReport -Append -NoNewline
            }
            else {
                $ErrReport = "$($user.userprincipalname),$($SKUstobeAdded[$i]),'NoErrors'"
                Out-File -FilePath $ErrLog -InputObject $ErrReport -Append -Encoding utf8
            }
        }
        else {
            $Report = "$($user.userprincipalname),is not assigned SKU:,$($SKUstobeAdded[$i]),Adding SKU with Base Options"
            Out-File -FilePath $Outfile -InputObject $Report -Append -Encoding utf8
            Write-Output "$($user.userprincipalname)`;is not assigned SKU:`;$($SKUstobeAdded[$i])`;Adding SKU with Base Options"
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SKUstobeAdded[$i] -DisabledPlans $BaseDisabled[$i]
            $data = (Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $SKUstobeAdded[$i] -LicenseOptions $LicenseOptions -ErrorAction Continue) 2>&1
            if ($($Data.Exception.message)) {
                $ErrReport = "$($user.userprincipalname),$($SKUstobeAdded[$i]),$($Data.Exception.message)"
                Out-File -FilePath $ErrLog -InputObject $ErrReport -Append -NoNewline
            }
            else {
                $ErrReport = "$($user.userprincipalname),$($SKUstobeAdded[$i]),'NoErrors'"
                Out-File -FilePath $ErrLog -InputObject $ErrReport -Append -Encoding utf8
            }
        }
    }
}