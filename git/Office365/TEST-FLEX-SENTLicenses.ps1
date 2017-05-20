$Users = Import-Csv .\ConAgraUsers.csv

Foreach ($user in $users) {
    $LicenseDetails = (Get-MsolUser -UserPrincipalName $User.UserPrincipalName).Licenses

    ForEach ($License in $LicenseDetails | ? {$_.accountskuid -eq 'cagrecipe:ENTERPRISEPACK'}) {
        $DisabledOptions = @()
        $License.ServiceStatus | ForEach {
            If ($_.ProvisioningStatus -eq "Disabled") {
                $DisabledOptions += "$($_.ServicePlan.ServiceName)"
            } 

        }

        $LicenseOptions = New-MsolLicenseOptions -AccountSkuId 'cagrecipe:ENTERPRISEPACK' -DisabledPlans $DisabledOptions

        Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName -LicenseOptions $LicenseOptions
        Write-Output $User.UserPrincipalName

    }
}