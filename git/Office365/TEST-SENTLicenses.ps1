function Test-SentLicenses {
    [CmdletBinding()]
    Param
    (
        # Users to be licensed
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]] $Users,

        [Parameter(Mandatory=$False)]
        [switch] $E3,
 
        [parameter(Mandatory=$False)]
        [switch] $EMS,
 
        [parameter(Mandatory=$False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "LockBox")]
        [string] $AddOption,
 
        [parameter(Mandatory=$False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "LockBox")]
        [string] $RemoveOption

    )

    Begin {
        # Hashtable for Options
        $hash = @{ 
            "Teams"   = "TEAMS1";
            "Sway"    = "SWAY";
            "Yammer"  = "YAMMER_ENTERPRISE";
            "Flow"    = "FLOW_O365_P3";       
            "Lockbox" = "LOCKBOX_ENTERPRISE"                             
        }

        # Assign Tenant and Location to a variable
        $Tenant     = "SENT"
        $Location   = "US"
        
        # Assign each AccountSkuID to a variable
        $TenantE3      = ($Tenant + ':ENTERPRISEPREMIUM')
        $TenantEMS     = ($Tenant + ':EMSPREMIUM')        
        
        
        # Zero Arrays
        $Options = @()
        $SKU = @()

        if($E3.IsPresent){
            # $TenantE3  = ($Tenant + ':ENTERPRISEPREMIUM')
            $LicenseE3 = New-MsolLicenseOptions -AccountSkuId $TenantE3
            $Options += $LicenseE3
            $SKU += $TenantE3
        }
        if($EMS.IsPresent){
            # $TenantEMS  = ($Tenant + ':EMSPREMIUM')  
            $LicenseEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
            $Options += $LicenseEMS 
            $SKU += $TenantEMS        
        }

    }
    Process {
        $DisabledOptions = @()
        if ($AddOption){
            $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
            ForEach ($License in $LicenseDetails | where {$_.accountskuid -eq "$TenantE3"}){
                $License.ServiceStatus | ForEach {
                    if ($_.ServicePlan.ServiceName -ne $hash[$AddOption]){
                        if ($_.ProvisioningStatus -eq "Disabled") {
                            $DisabledOptions += "$($_.ServicePlan.ServiceName)"
                        }
                    } 
                }
            }
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantE3 -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptions    
        }
        if ($RemoveOption){
            $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
            ForEach ($License in $LicenseDetails | where {$_.accountskuid -eq "$TenantE3"}){
                $License.ServiceStatus | ForEach {
                    if ($_.ProvisioningStatus -eq "Disabled" -or $_.ServicePlan.ServiceName -eq $hash[$RemoveOption]) {
                        $DisabledOptions += "$($_.ServicePlan.ServiceName)"
                    } 
                }
            }
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantE3 -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptions
        }
        if (!($AddOption -or $RemoveOption)){
            $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
            if ($E3 -and $LicenseDetails.accountskuid -match $TenantE3){
                Write-Output "$($_.UserPrincipalName) already has the SKU: $TenantE3"
            }
            if ($EMS -and $LicenseDetails.accountskuid -match $TenantEMS){
                Write-Output "$($_.UserPrincipalName) already has the SKU: $TenantEMS"
            }
            if ($E3 -and $LicenseDetails.accountskuid -notmatch $TenantE3){
                if ($EMS -and $LicenseDetails.accountskuid -notmatch $TenantEMS){
                    Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
                    Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses $SKU -LicenseOptions $Options
                }
            }
        }
    }
    End {
    }
}