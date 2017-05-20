<#

#>

# Zero Variables and Define Arrays
$BaseDisabled = @()
$addsku = @()
$addop = @()
$remop = @()
$user = @()
$basesku = @()
$numadd = 0 
$numrem = 0
$numsku = 0
$numbase = 0

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
        
# Set Base Disabled Options for E3    
$BaseDisabled = 'Deskless', 'FLOW_O365_P2', 'POWERAPPS_O365_P2', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY', 'INTUNE_O365', 'YAMMER_ENTERPRISE', 'RMS_S_ENTERPRISE', 'MCOVOICECONF', 'MCOSTANDARD', 'SHAREPOINTWAC', 'SHAREPOINTENTERPRISE'

# Start Transcript of PowerShell Session
Start-Transcript -Path '.\Office365_PowerShell.txt' -Append

# Input Files
$LicTheseUsersPath = '.\LicenseUserlist.csv'
$LicenseTheseUsers = Get-Content $LicTheseUsersPath
$CurrentlyLicensed = Get-MsolUser -All | ? {$_.IsLicensed -eq 'True'}

# Error Log
$LogPreference = ($(get-date -Format yyyy-MM-dd_HH-mm-ss) + "-error.txt")
$ErrorsHappened = $False

# Remove All Skus
ForEach ($row in $CurrentlyLicensed | Where {$_.UserPrincipalName -ne  })

# Add SKUs (or Remove SKUs) requested by user  
if ($numsku) {
    for ($i = 0; $i -lt $numsku; $i++) {
        $FullSku = @()
        if (!($RemoveSKU.IsPresent)) {
            if ($user.licenses.accountskuid -match $addsku[$i]) {
                $FullSku = New-MsolLicenseOptions -AccountSkuId $addsku[$i]
                Write-Output "$($user.userprincipalname) is already assigned SKU: $($addsku[$i]). All Options will be added now"
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $FullSku    
            }
            else {
                Write-Output "$($user.userprincipalname) is not assigned SKU: $($addsku[$i]). Assigning SKU now"
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $addsku[$i]
            }
        }
        # Remove SKUs requested by user
        else {
            if ($user.licenses.accountskuid -match $addsku[$i]) {
                Write-Output "$($user.userprincipalname) is assigned SKU: $($addsku[$i]). REMOVING SKU now"
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -RemoveLicenses $addsku[$i] -Verbose   
            }
            else {
                Write-Output "$($user.userprincipalname) is not assigned SKU: $($addsku[$i]). No need to remove."
            }
        }
    }
}
# Adding options requested by user
if ($numadd) {
    for ($i = 0; $i -lt $numadd; $i++) {
        $DisabledOptions = @()
        $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName
        if ($user.licenses.accountskuid -match $hash4sku[$addop[$i]]) {
            ForEach ($License in $user.licenses | where {$_.AccountSkuID -match $hash4sku[$addop[$i]]}) {
                        
                $License.ServiceStatus | ForEach {
                    if ($_.ServicePlan.ServiceName -ne $hash[$addop[$i]] -and $_.ProvisioningStatus -eq "Disabled") {
                        $DisabledOptions += $_.ServicePlan.ServiceName
                    }
                }
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hash4sku[$addop[$i]] -DisabledPlans $DisabledOptions
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction SilentlyContinue -ErrorVariable dependency
                if ($dependency) {
                    Write-Warning "Unable to add: $($addop[$i])`, probably due to a dependency"
                }
                else {
                    Write-Output "$($user.userprincipalname) adding option: $($addop[$i])"
                }
            }              
        }  
        else {
            Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $hash4sku[$addop[$i]]
            $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName
            ForEach ($License in $user.licenses | where {$_.AccountSkuID -eq $hash4sku[$addop[$i]]}) {
                $License.ServiceStatus | ForEach {
                    if ($_.ServicePlan.ServiceName -ne $hash[$addop[$i]]) {
                        $DisabledOptions += $_.ServicePlan.ServiceName
                    }
                }
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hash4sku[$addop[$i]] -DisabledPlans $DisabledOptions
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction SilentlyContinue -ErrorVariable dependency
                if ($dependency) {
                    Write-Warning "Unable to add: $($addop[$i])`, probably due to a dependency"
                }
                else {
                    Write-Output "$($user.userprincipalname) does not have the SKU: $($hash4sku[$addop[$i]])`. Adding SKU with only $($addop[$i])"
                }
            }
        }
    }
}
# Remove options requested by user
if ($numrem) {
    for ($i = 0; $i -lt $numrem; $i++) {
        $DisabledOptions = @()
        $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName
        if ($user.licenses.accountskuid -match $hash4sku[$remop[$i]]) {
            ForEach ($License in $user.licenses | where {$_.AccountSkuID -match $hash4sku[$remop[$i]]}) {
                $License.ServiceStatus | ForEach {
                    if ($_.ProvisioningStatus -eq "Disabled" -or $_.ServicePlan.ServiceName -eq $hash[$remop[$i]]) {
                        $DisabledOptions += $_.ServicePlan.ServiceName
                    } 
                }
            }
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hash4sku[$remop[$i]] -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction SilentlyContinue -ErrorVariable dependency
            if ($dependency) {
                Write-Warning "Unable to remove: $($remop[$i])`, probably due to a dependency"
            }
            else {
                Write-Output "$($user.userprincipalname) removing option: $($remop[$i])"
            }
        }
        else {
            Write-Output "$($user.userprincipalname) does not have SKU: $($hash4sku[$remop[$i]])`, cannot remove option: $($remop[$i])"
        }
    }
}
# If no switches or options provided, user(s) will recieve a base license (predefined by I.T. dept)
if ($basesku) {
    Try {
        $remskus = @()
        for ($i = 0; $i -lt $basenum; $i++) {
            if ($user.licenses.accountskuid -match $basesku[$i]) {
                Write-Output "$($user.userprincipalname) is assigned the SKU: $($basesku[$i]). Removing SKU now"
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -RemoveLicenses $basesku[$i] -Verbose -ErrorAction Continue
            }        
        }
        if ($user.licenses.accountskuid -match $SkuE3) {
            Write-Output "$($user.userprincipalname) is already assigned SKU: $($SkuE3). Modifying options if necessary."
            ForEach ($License in $user.licenses | Where {$_.AccountSkuID -eq $SkuE3}) {
                $License.ServiceStatus | ForEach {
                    if ($_.ServicePlan.ServiceName -eq "OFFICESUBSCRIPTION") {
                        $DisabledOptions += $_.ServicePlan.ServiceName
                    }
                }
            }
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SkuE3 -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction Continue      
        }
        else {
            Write-Output "$($user.userprincipalname) is not assigned SKU: $($SkuE3)`. Adding SKU with Base Options"
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SkuE3 -DisabledPlans $BaseDisabled
            Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $SkuE3 -LicenseOptions $LicenseOptions -ErrorAction Continue
        }
    }
    catch {
        $user.UserPrincipalName | Out-File $ErrorLog -Append
        $ErrorsHappened = $true
    }
}
} #End of Process Block 
End {
    if ($ErrorsHappened) {
        Write-Warning "Errors logged to $ErrorLog"
    }
}
}