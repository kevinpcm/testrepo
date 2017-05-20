<#

    .SYNOPSIS 
        The user of this script can perform one or more of the following tasks against one more Office 365 users:

        1.  Add a full license with all options (SKU) (ex. E3)
        2.  Add a single option (ex. Teams). If the user does not currently have the SKU assigned, it 
            will be added with only the single option.
        3.  Remove a single option
        4.  Add a "Base" set of options - Defined by I.T. as these SKU's:
             a.  SKU: EMS (all options)
             b.  SKU: E3  (sans these options: 'StaffHub', 'Flow', 'PowerApps', 'Teams', 'Planner', 'Sway')


            
    .DESCRIPTION
        Summary: 
                Use this function to license users for Office 365.  
                UserPrincipalName(s) are passed with a variable from the pipeline "|" to the function Set-ConAgraLicense.
                
        There are two primary methods to add a list of UPN(s) to a variable:

        1.  By using a CSV (ex. $users = Import-CSV .\anylistofupns.csv)
        2.  By using Get-MsolUser and filtered parameters (ex. $users = Get-MsolUser -Department "BRM Admin")
            For a full list of parameters on which to filter, execute this command: help Get-MsolUser -Full

        If a CSV is used:
        
        1.  Must have a column populated with UPN(s)
        2.  The column of UPN(s) must have a header named, UserPrincipalName
        3.  The CSV may contain other columns as they will be ignored


        Example of CSV
        ------- -- ---

        UserPrincipalName
        ZGA0101@conagrafoods.com
        ZMA0280@conagrafoods.com
        BFA0123@conagrafoods.com
        BFA0190@conagrafoods.com

        Mandatory parameters are: 
                Users
                
        Non-Mandatory parameters are: 
                E3, EMS, RemoveSKU, AddOption, RemoveOption, AddOptionNonE3, RemoveOptionNonE3

    .EXAMPLE
        Adds the base set of options to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses

    .EXAMPLE
        Adds the base set of options to a list of Office 365 user(s) from a filtered list of Get-MsolUser

        . .\Set-365Licenses.ps1
        $Users = Get-MsolUser -Department "BRM Admin"
        $Users | Set-ConAgraLicenses

    .EXAMPLE
        Adds the SKUs E3 and EMS (with all options) to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -E3 -EMS

    .EXAMPLE
        Adds the option "Microsoft Teams" to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -AddOption Teams

    .EXAMPLE
        Removes the option "Microsoft Sway" from a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -RemoveOption Sway
   
    .EXAMPLE
        Removes the SKUs E3 and EMS from a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicenses -E3 -EMS -RemoveSKU
   
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
        [switch] $RemoveSKU,
 
        [parameter(Mandatory=$False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange")]
        [string] $AddOption,
 
        [parameter(Mandatory=$False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange")]
        [string] $RemoveOption,
       
        [parameter(Mandatory=$False)]
        [ValidateSet("Intune", "Cloud_App_Security", "Azure_AD_Premium", "Azure_AD_Premium_P2")]
        [string] $AddOptionNonE3,
       
        [parameter(Mandatory=$False)]
        [ValidateSet("Intune", "Cloud_App_Security", "Azure_AD_Premium", "Azure_AD_Premium_P2")]
        [string] $RemoveOptionNonE3

    )

    Begin {
        # Zero
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

        # Hashtable for Options
        $hash = @{ 
            "Teams"               = "TEAMS1";
            "Sway"                = "SWAY";
            "Yammer"              = "YAMMER_ENTERPRISE";
            "Flow"                = "FLOW_O365_P3";       
            "OfficePro"           = "OFFICESUBSCRIPTION";
            "StaffHub"            = "Deskless";
            "Planner"             = "PROJECTWORKMANAGEMENT";
            "PowerApps"           = "POWERAPPS_O365_P3";
            "AzureRMS"            = "RMS_S_ENTERPRISE";
            "OfficeOnline"        = "SHAREPOINTWAC";
            "SharePoint"          = "SHAREPOINTENTERPRISE";
            "Skype"               = "MCOSTANDARD";
            "Exchange"            = "EXCHANGE_S_ENTERPRISE";
            "Intune"              = "INTUNE_A";
            "Cloud_App_Security"  = "ADALLOM_S_STANDALONE";
            "Azure_AD_Premium_P2" = "AAD_PREMIUM_P2";
            "Azure_AD_Premium"    = "AAD_PREMIUM"
        }

        # Hashtable to match Options to their SKUs
        $hash4sku = @{ 
            "Teams"               = "sent:ENTERPRISEPREMIUM";
            "Sway"                = "sent:ENTERPRISEPREMIUM";
            "Yammer"              = "sent:ENTERPRISEPREMIUM";
            "Flow"                = "sent:ENTERPRISEPREMIUM";
            "OfficePro"           = "sent:ENTERPRISEPREMIUM";
            "StaffHub"            = "sent:ENTERPRISEPREMIUM";
            "Planner"             = "sent:ENTERPRISEPREMIUM";
            "PowerApps"           = "sent:ENTERPRISEPREMIUM";
            "AzureRMS"            = "sent:ENTERPRISEPREMIUM";
            "OfficeOnline"        = "sent:ENTERPRISEPREMIUM";
            "SharePoint"          = "sent:ENTERPRISEPREMIUM";
            "Skype"               = "sent:ENTERPRISEPREMIUM";
            "Exchange"            = "sent:ENTERPRISEPREMIUM";
            "Intune"              = "sent:EMSPREMIUM";
            "Cloud_App_Security"  = "sent:EMSPREMIUM";
            "Azure_AD_Premium_P2" = "sent:EMSPREMIUM";
            "Azure_AD_Premium"    = "sent:EMSPREMIUM"
        }

        # Assign Tenant and Location to a variable
        $Tenant     = "SENT"
        $Location   = "US"
        
        # Assign each AccountSkuID to a variable
        $TenantE3      = ($Tenant + ':ENTERPRISEPREMIUM')
        $TenantEMS     = ($Tenant + ':EMSPREMIUM')        
        $BaseDisabled  = 'Deskless', 'FLOW_O365_P3', 'POWERAPPS_O365_P3', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY'
        
        # Start Transcript of PowerShell Session
        Start-Transcript -Path '.\ConAgra_Office365_PowerShell.txt' -Append

        # Check if SKUs are being slated to be modified
        if ($E3.IsPresent){
            $numsku++
            $addsku += $TenantE3
        }
        if ($EMS.IsPresent){
            $numsku++
            $addsku += $TenantEMS
        }
        
        # Compile a list of Options are being added
        if ($AddOption -or $AddOptionNonE3){
            if ($AddOption){
                $numadd++
                $addop += $AddOption
            }
            if ($AddOptionNonE3){
                $numadd++
                $addop += $AddOptionNonE3
            }
        }

        # Compile a list of Options are being removed
        if ($RemoveOption -or $RemoveOptionNonE3){
            if ($RemoveOption){
                $numrem++
                $remop += $RemoveOption
            }
            if ($RemoveOptionNonE3){
                $numrem++
                $remop += $RemoveOptionNonE3
            }
        }
        # Compile Base Options
        if (!($numsku -or $numadd -or $numrem)){
            $basesku += $TenantE3
            $basesku += $TenantEMS
        }
    }

    Process {
        $DisabledOptions = @()      
        $action = 0

        # Compile all user's attributes from UPN
        $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName

        # Set User's Location
        Set-MsolUser -UserPrincipalName $user.userprincipalname -UsageLocation $Location

        # Add SKUs requested by user  
        if ($numsku){
            $action++
            for ($i=0; $i -lt $numsku; $i++){
                $FullSku = @()
                if (!($RemoveSKU.IsPresent)){
                    if ($user.licenses.accountskuid -match $addsku[$i]){
                        $FullSku = New-MsolLicenseOptions -AccountSkuId $addsku[$i]
                        Write-Output "$($user.userprincipalname) already has SKU: $($addsku[$i]). All Options will be added now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $FullSku    
                    }
                    else {
                        Write-Output "$($user.userprincipalname) does not have SKU: $($addsku[$i]). The SKU will be added now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $addsku[$i]
                    }
                }
                # Remove SKUs requested by user
                else {
                    if ($user.licenses.accountskuid -match $addsku[$i]){
                        Write-Output "$($user.userprincipalname) has SKU: $($addsku[$i]). The SKU will be REMOVED now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -RemoveLicenses $addsku[$i] -Verbose   
                    }
                }
            }
        }
        # Adding options requested by user
        if ($numadd){
            if ($action){
                $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName
            }
            $action++
            for ($i=0; $i -lt $numadd; $i++){
                if ($user.licenses.accountskuid -match $hash4sku[$addop[$i]]){
                    ForEach ($License in $user.licenses | where {$_.AccountSkuID -match $hash4sku[$addop[$i]]}){
                        $License.ServiceStatus | ForEach {
                            if ($_.ServicePlan.ServiceName -ne $hash[$addop[$i]] -and $_.ProvisioningStatus -eq "Disabled"){
                                $DisabledOptions += $_.ServicePlan.ServiceName
                            }
                        }
                        $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hash4sku[$addop[$i]] -DisabledPlans $DisabledOptions
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction SilentlyContinue -ErrorVariable dependency
                        if ($dependency){
                            Write-Warning "Unable to add: $($addop[$i])`, probably due to a dependency"
                        }
                        else {
                            Write-Output "$($user.userprincipalname) adding option: $($addop[$i])"
                        }
                    }              
                }  
                else {
                    Write-Output "$($user.userprincipalname) does not have the SKU: $($hash4sku[$addop[$i]])`. Adding SKU with only $($addop[$i])"
                    Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $hash4sku[$addop[$i]]
                    ForEach ($License in $user.licenses | where {$_.AccountSkuID -eq $hash4sku[$addop[$i]]}){
                        $License.ServiceStatus | ForEach {
                            if ($_.ServicePlan.ServiceName -ne $hash[$addop[$i]]){
                                $DisabledOptions += $_.ServicePlan.ServiceName
                            }
                        }
                    }
                }
            }
        }
        # Remove options requested by user
        if ($numrem){
            if ($action){
                $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName
            }
            $action++
            for ($i=0; $i -lt $numrem; $i++){
                $DisabledOptions = @()
                if ($user.licenses.accountskuid -match $hash4sku[$remop[$i]]){
                    ForEach ($License in $user.licenses | where {$_.AccountSkuID -match $hash4sku[$remop[$i]]}){
                        $License.ServiceStatus | ForEach {
                            if ($_.ProvisioningStatus -eq "Disabled" -or $_.ServicePlan.ServiceName -eq $hash[$remop[$i]]) {
                                $DisabledOptions += $_.ServicePlan.ServiceName
                            } 
                        }
                    }
                    $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $hash4sku[$remop[$i]] -DisabledPlans $DisabledOptions
                    Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction SilentlyContinue -ErrorVariable dependency
                    if ($dependency){
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
        if ($basesku){
            if ($user.licenses.accountskuid -match $TenantE3){
                ForEach ($License in $user.licenses | Where {$_.AccountSkuID -eq $TenantE3}){
                    $License.ServiceStatus | ForEach {
                        if ($_.ServicePlan.ServiceName -eq "Deskless" -or $_.ServicePlan.ServiceName -eq "FLOW_O365_P3" -or $_.ServicePlan.ServiceName -eq "POWERAPPS_O365_P3" -or $_.ServicePlan.ServiceName -eq "TEAMS1" -or $_.ServicePlan.ServiceName -eq "PROJECTWORKMANAGEMENT" -or $_.ServicePlan.ServiceName -eq "SWAY"){
                            $DisabledOptions += $_.ServicePlan.ServiceName
                        }
                    }
                }
                Write-Output "$($user.userprincipalname) has SKU: $($TenantE3)`, verifying base options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantE3 -DisabledPlans $DisabledOptions
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions        
            }
            else {
                Write-Output "$($user.userprincipalname) does not have SKU: $($TenantE3)`. Adding SKU with Base Options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantE3 -DisabledPlans $BaseDisabled
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $TenantE3 -LicenseOptions $LicenseOptions
            }
            if ($user.licenses.accountskuid -match $TenantEMS){
                Write-Output "$($user.userprincipalname) has SKU: $($TenantEMS)`, verifying base options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantEMS
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions             
            }
            else {
                Write-Output "$($user.userprincipalname) does not have SKU: $($TenantEMS)`. Adding SKU with Base Options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $TenantEMS
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $TenantEMS -LicenseOptions $LicenseOptions
            }
        }
    } #End of Process Block 
    End {
    }
}