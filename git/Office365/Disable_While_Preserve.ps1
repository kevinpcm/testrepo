$Users = Import-Csv .\CAphase2.1.csv

Foreach ($user in $users) {
    $LicenseDetails = (Get-MsolUser -UserPrincipalName $User.UserPrincipalName).Licenses
    ForEach ($License in $LicenseDetails | ? {$_.accountskuid -eq 'cagrecipe:ENTERPRISEPACK'}) {
        $DisabledOptions = @()
        $License.ServiceStatus | ForEach {
            If ($_.ServicePlan.ServiceName -like "Deskless" -or $_.ServicePlan.ServiceName -like "FLOW_O365_P2" -or  $_.ServicePlan.ServiceName -like "POWERAPPS_O365_P2" -or  $_.ServicePlan.ServiceName -like "TEAMS1" -or  $_.ServicePlan.ServiceName -like "PROJECTWORKMANAGEMENT" -or  $_.ServicePlan.ServiceName -like "SWAY" -or  $_.ServicePlan.ServiceName -like "MCOSTANDARD") {
                $DisabledOptions += "$($_.ServicePlan.ServiceName)" 
            } 
        }
        $LicenseOptionsE3  = New-MsolLicenseOptions -AccountSkuId 'cagrecipe:ENTERPRISEPACK' -DisabledPlans $DisabledOptions
        $LicenseOptionsEMS = New-MsolLicenseOptions -AccountSkuId 'cagrecipe:EMS'
        Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName -AddLicenses 'cagrecipe:EMS' -LicenseOptions $LicenseOptionsE3, $LicenseOptionsEMS
        Write-Output $User.UserPrincipalName
    }
}