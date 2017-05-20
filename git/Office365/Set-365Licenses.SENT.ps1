<#

    .SYNOPSIS 
        1.	Enables Organization Customization in tenant, if it hasn’t already been enabled.
        2.	Creates a Retention Policy specified at run-time (or uses one that already exists by the same name)

            
    .DESCRIPTION
        There are 3 things this function creates as new:
        1. Retention Policy [One] (if already exists, new RPTs will be linked to it)
        
        Summary: 
                Use this function to create retention tags and link them to a new or existing retention policy. 

        Mandatory parameters are: 
                Users
                
        Non-Mandatory parameters are: 
                DefaultPolicyTagName, AgeLimitDPT, ActionDPT, ActionRPT, PreventPersonalTags, CustomRoleAssignmentPolicy

    .EXAMPLE
        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -E3

    .EXAMPLE
        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -E3 -EMS

    .EXAMPLE
        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -AddOption Teams

    .EXAMPLE
        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -RemoveOption Sway

    .EXAMPLE   
        Example of: CSV
        UserPrincipalName
        ZGA0101@conagrafoods.com
        ZMA0280@conagrafoods.com
        BFA0123@conagrafoods.com
        BFA0190@conagrafoods.com
        ZDA0119@conagrafoods.com
        ZBA0086@conagrafoods.com
        ZRA0125@conagrafoods.com
         
#>
function Set-ConAgraLicenses {
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
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "INTUNE_A", "CLOUD_APP_SECURITY")]
        [string] $AddOption,
 
        [parameter(Mandatory=$False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "INTUNE_A", "CLOUD_APP_SECURITY")]
        [string] $RemoveOption

    )

    Begin {

        # Zero Arrays
        $BaseDisabled = @()
        $Options = @()
        $OptionsFill = @()
        $SKU = @()
        
        # Hashtable for Options
        $hash = @{ 
            "Teams"              = "TEAMS1";
            "Sway"               = "SWAY";
            "Yammer"             = "YAMMER_ENTERPRISE";
            "Flow"               = "FLOW_O365_P3";       
            "OfficePro"          = "OFFICESUBSCRIPTION";
            "StaffHub"           = "Deskless";
            "Planner"            = "PROJECTWORKMANAGEMENT";
            "PowerApps"          = "POWERAPPS_O365_P3";
            "AzureRMS"           = "RMS_S_ENTERPRISE";
            "OfficeOnline"       = "SHAREPOINTWAC";
            "SharePoint"         = "SHAREPOINTENTERPRISE";
            "Skype"              = "MCOSTANDARD";
            "Exchange"           = "EXCHANGE_S_ENTERPRISE";
            "INTUNE_A"           = "INTUNE_A";
            "CLOUD_APP_SECURITY" = "ADALLOM_S_STANDALONE"
        }

        # Hashtable for Options
        $hashoptions = @{ 
            "Teams"              = "sent:ENTERPRISEPREMIUM";
            "Sway"               = "sent:ENTERPRISEPREMIUM";
            "Yammer"             = "sent:ENTERPRISEPREMIUM";
            "Flow"               = "sent:ENTERPRISEPREMIUM";
            "OfficePro"          = "sent:ENTERPRISEPREMIUM";
            "StaffHub"           = "sent:ENTERPRISEPREMIUM";
            "Planner"            = "sent:ENTERPRISEPREMIUM";
            "PowerApps"          = "sent:ENTERPRISEPREMIUM";
            "AzureRMS"           = "sent:ENTERPRISEPREMIUM";
            "OfficeOnline"       = "sent:ENTERPRISEPREMIUM";
            "SharePoint"         = "sent:ENTERPRISEPREMIUM";
            "Skype"              = "sent:ENTERPRISEPREMIUM";
            "Exchange"           = "sent:ENTERPRISEPREMIUM";
            "INTUNE_A"           = "sent:EMSPREMIUM";
            "CLOUD_APP_SECURITY" = "sent:EMSPREMIUM"
        }

        # Assign Tenant and Location to a variable
        $Tenant     = "SENT"
        $Location   = "US"
        
        # Assign each AccountSkuID to a variable
        $TenantE3      = ($Tenant + ':ENTERPRISEPREMIUM')
        $TenantEMS     = ($Tenant + ':EMSPREMIUM')        
        $BaseDisabled  = 'Deskless', 'FLOW_O365_P3', 'POWERAPPS_O365_P3', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY'
        
    }
    Process {
        $DisabledOptions = @()
        $SKU = @()
        $Options = @()
        $OptionsFill = @()

        if ($AddOption){
            $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
            ForEach ($License in $LicenseDetails | where {$_.accountskuid -eq $hashoptions[$AddOption]}){
                $License.ServiceStatus | ForEach {
                    if ($_.ServicePlan.ServiceName -ne $hash[$AddOption]){
                        if ($_.ProvisioningStatus -eq "Disabled") {
                            $DisabledOptions += "$($_.ServicePlan.ServiceName)"
                        }
                    } 
                }
            }
            Write-Output "$($_.UserPrincipalName) receiving option: $AddOption"
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hashoptions[$AddOption] -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptions    
        }
        if ($RemoveOption){
            Write-Output "$($_.UserPrincipalName) removing option: $RemoveOption"
            $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
            ForEach ($License in $LicenseDetails | where {$_.accountskuid -eq $hashoptions[$RemoveOption]}){
                $License.ServiceStatus | ForEach {
                    if ($_.ProvisioningStatus -eq "Disabled" -or $_.ServicePlan.ServiceName -eq $hash[$RemoveOption]) {
                        $DisabledOptions += "$($_.ServicePlan.ServiceName)"
                    } 
                }
            }
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hashoptions[$RemoveOption] -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptions
        }
        if (!($AddOption -or $RemoveOption)){
            if($E3.IsPresent){
                $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
                if ("$($LicenseDetails.accountskuid)" -notmatch $TenantE3){
                    $LicenseE3 = New-MsolLicenseOptions -AccountSkuId $TenantE3
                    $OptionsE3 += $LicenseE3
                    $SKUE3 += $TenantE3
                }
                else {
                    Write-Output "$($_.UserPrincipalName) already has the SKU: $TenantE3 : Adding any missing Options"
                    $LicenseE3 = New-MsolLicenseOptions -AccountSkuId $TenantE3
                    $OptionsFillE3 += $LicenseE3
                    $SKUE3 += $TenantE3
                }
            }
            if($EMS.IsPresent){
                $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
                if ("$($LicenseDetails.accountskuid)" -notmatch $TenantEMS){
                    $LicenseEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
                    $OptionsEMS += $LicenseEMS
                    $SKUEMS += $TenantEMS
                }
                else {
                    Write-Output "$($_.UserPrincipalName) already has the SKU: $TenantEMS : Adding any missing Options"
                    $LicenseEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
                    $OptionsFillEMS += $LicenseEMS
                    $SKUEMS += $TenantEMS
                }
            }
        }
        if($OptionsE3){
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses $SKUE3 -LicenseOptions $OptionsE3
        }
        if($OptionsEMS){
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses $SKUEMS -LicenseOptions $OptionsEMS
        }
        if($OptionsFillE3){
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $OptionsFillE3
        }
        if($OptionsFillEMS){
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $OptionsFillEMS
        }
        if (!($AddOption -or $RemoveOption -or $E3.IsPresent -or $EMS.IsPresent)){
            Write-Output "$($_.UserPrincipalName) receiving option: Base"
            $LicenseOptionsE3  = New-MsolLicenseOptions -AccountSkuId $TenantE3 -DisabledPlans $BaseDisabled
            $LicenseOptionsEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
            if ("$($LicenseDetails.accountskuid)" -notmatch $TenantE3){
                Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses $TenantE3 -LicenseOptions $LicenseOptionsE3
            }
            else {
                Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptionsE3
            }
            if ("$($LicenseDetails.accountskuid)" -notmatch $TenantEMS){
                Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses $TenantEMS -LicenseOptions $LicenseOptionsEMS
            }
            else {
                Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptionsEMS
            }
            
        }
    }
    End {
    }
}