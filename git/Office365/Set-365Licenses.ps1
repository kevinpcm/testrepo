<#

    .SYNOPSIS 
        1.	Enables Organization Customization in tenant, if it hasn’t already been enabled.
        2.	Creates a Retention Policy specified at run-time (or uses one that already exists by the same name)
        3.	Imports from a txt file or directly from pipeline, a list of Outlook Default Folders. For example:
            a.	Mail Folders (such as... Inbox, Sent Items etc.)
            b.	Non-Mail Folders (such as... Calendar, Contacts, Tasks etc.)
        4.	Creates Retention Policy Tags (RPT)
            a.  Name comprised of a TagPrefix + Folder + Suffix (Suffix is auto-generated based on # of days)
            b.	TagPrefix/RetentionAge/Action defined at run-time
            c.  When specifying parameter -ActionRPT, user can tab through the four available choices
            d.	If the RPT already exists, script will silently continue
        5.	Creates a Default Policy Tag (DPT) if specified (not mandatory)
            a.  Name comprised of a TagPrefix + DefaultPolicyTagName + Suffix (Suffix is auto-generated based on # of days)
            b.	TagPrefix/RetentionAge/Action defined at run-time
            c.  When specifying parameter -ActionDPT, user can tab through the four available choices
            d.	If the specified DPT already exists, script will silently continue
            e.  If the Retention Policy specified already has a DPT linked to it, script will output to screen which DPT is linked and continue
        6.	For indefinite RetentionAge/AgeLimit, specify a value of "0" for the parameters, AgeLimitRPT and/or AgeLimitDPT
        7.	The specifed Retention Policy will be automatically linked to any RPTs and a DPT, IF they were created by the script
        8.	If desired, script removes the ability for end-users to create and use Personal Tags (which override DPT & RPTs) by:
            a.	Removing "MyRetentionPolicies" role from the default role assignment policy named, "Default Role Assignment Policy"
            b.	The policy, "Default Role Assignment Policy" is utilized unless the switch, "-CustomRoleAssignmentPolicy" is used to specify another Management Role Assignment Policy

            
    .DESCRIPTION
        There are 3 things this function creates as new:
        1. Retention Policy [One] (if already exists, new RPTs will be linked to it)
        2. Retention Policy Tags [One or More] (created, and then linked to specified Retention Policy)
        3. Default Policy Tag [Zero or One] (Only one DPT can be linked to a single Retention Policy, so the script checks if a DPT is already linked prior to trying to link another)
        
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
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange")]
        [string] $AddOption,
 
        [parameter(Mandatory=$False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange")]
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
            "Teams"         = "TEAMS1";
            "Sway"          = "SWAY";
            "Yammer"        = "YAMMER_ENTERPRISE";
            "Flow"          = "FLOW_O365_P2";       
            "OfficePro"     = "OFFICESUBSCRIPTION";
            "StaffHub"      = "Deskless";
            "Planner"       = "PROJECTWORKMANAGEMENT";
            "PowerApps"     = "POWERAPPS_O365_P2";
            "AzureRMS"      = "RMS_S_ENTERPRISE";
            "OfficeOnline"  = "SHAREPOINTWAC";
            "SharePoint"    = "SHAREPOINTENTERPRISE";
            "Skype"         = "MCOSTANDARD";
            "Exchange"      = "EXCHANGE_S_ENTERPRISE"
        }

        # Assign Tenant and Location to a variable
        $Tenant     = "cagrecipe"
        $Location   = "US"
        
        # Assign each AccountSkuID to a variable
        $TenantE3      = ($Tenant + ':ENTERPRISEPACK')
        $TenantEMS     = ($Tenant + ':EMS')        
        $BaseDisabled  = 'Deskless', 'FLOW_O365_P2', 'POWERAPPS_O365_P2', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY'
        
    }
    Process {
        $DisabledOptions = @()
        $SKU = @()
        $Options = @()
        $OptionsFill = @()

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
            Write-Output "$($_.UserPrincipalName) receiving option: $AddOption"
            $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantE3 -DisabledPlans $DisabledOptions
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $LicenseOptions    
        }
        if ($RemoveOption){
            Write-Output "$($_.UserPrincipalName) removing option: $RemoveOption"
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
            if($E3.IsPresent){
                $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
                if ("$($LicenseDetails.accountskuid)" -notmatch $TenantE3){
                    $LicenseE3 = New-MsolLicenseOptions -AccountSkuId $TenantE3
                    $Options += $LicenseE3
                    $SKU += $TenantE3
                }
                else {
                    Write-Output "$($_.UserPrincipalName) already has the SKU: $TenantE3 : Adding any missing Options"
                    $LicenseE3 = New-MsolLicenseOptions -AccountSkuId $TenantE3
                    $OptionsFill += $LicenseE3
                    $SKU += $TenantE3
                }
            }
            if($EMS.IsPresent){
                $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
                if ("$($LicenseDetails.accountskuid)" -notmatch $TenantEMS){
                    $LicenseEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
                    $Options += $LicenseEMS
                    $SKU += $TenantEMS
                }
                else {
                    Write-Output "$($_.UserPrincipalName) already has the SKU: $TenantEMS : Adding any missing Options"
                    $LicenseEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
                    $OptionsFill += $LicenseEMS
                    $SKU += $TenantEMS
                }
            }
        }
        if($Options){
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses $SKU -LicenseOptions $Options
        }
        if($OptionsFill){
            Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
            Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -LicenseOptions $OptionsFill
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