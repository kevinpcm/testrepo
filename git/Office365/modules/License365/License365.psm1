function Set-365License {
    <#
    .SYNOPSIS 
        The user of this script can perform one or more of the following tasks against one or more Office 365 users:

        1.  Add a full license (SKU) with all options (ex. E3)
        2.  Add between one and three options (ex. Teams). If the user does not currently have the SKU assigned, it 
            will be added with only the option(s).
        3.  Remove between one and three option(s)
        4.  Automatically selects a "Base" set of options - Defined by I.T.
            This occurs when no options are selected at all.  See examples in the EXAMPLE section below
              a.  Remove: SKU: Exchange Online (Plan2)
              b.  Remove: SKU: Office 365 Enterprise E1
              c.  Remove: SKU: Office 365 Enterprise E2
              d.  Remove: SKU: SharePoint Online (Plan 2)
              e.  Add:    SKU: Office 365 Enterprise E3 (sans the option(s): 'OfficeProPlus')
        5.  Remove one or more SKU's

        =============
        Prerequisites
        =============
        
        1.  Download and install the Microsoft Online Services Sign-In Assistant
              https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi

        2.  If not running Windows 10 or higher, Install WMF 5.1 or higher
              https://www.microsoft.com/en-us/download/details.aspx?id=54616 
        
        3.  Install the Windows Azure Active Directory Module for Windows PowerShell. From an elevated PowerShell prompt run
              Install-Module -Name MSOnline
        
        4.  From an elevated PowerShell prompt run:
              Set-ExecutionPolicy RemoteSigned -Force
        
        5.  The script files provided (including the folder they came in) must be copied to "C:\Program Files\WindowsPowerShell\Modules".
              Alternatively, the folder and files can be copied to any folder listed when executing, $env:PSModulepath -split ";" from PS.
        
        6.  To begin using the script(s), from an elevated PowerShell prompt run: 
              Import-Module License365

        7.  If not already connected to Office 365 from an elevated PowerShell prompt run (you will be prompted for appropriate credentials):
              Connect-Office365
            
    .DESCRIPTION
        Summary
                Use this function to license users for Office 365.  
                UserPrincipalName(s) are passed with a variable from the pipeline "|" to the function Set-365License.
        
        There are two primary methods to add a list of UPN(s) to a variable

        1.  By using a CSV (Example: $users = Import-CSV .\anylistofupns.csv)
        2.  By using Get-MsolUser and filtered parameters
              a.  Example: $users = Get-MsolUser -Department "IT Department"
              b.  Example: $users = Get-MsolUser -SearchString user1
              c.  For a full list of parameters on which to filter, execute this command: help Get-MsolUser -Full

        If a CSV is used
        
        1.  Must have a column populated with UPN(s)
        2.  The column of UPN(s) must have a header named, UserPrincipalName
        3.  The CSV may contain other columns as they will be ignored

        Example of CSV
        ------- -- ---

        UserPrincipalName
        user1@portofsandiego.org
        user2@portofsandiego.org
        user3@portofsandiego.org
        user4@portofsandiego.org

        Mandatory parameters are
            Users (ValueFromPipeline)
                
        Non-Mandatory parameters are: 
            E3, EMS, RemoveSKU, AddOption, AddOption2, AddOption3, RemoveOption, RemoveOption2, RemoveOption3, PowerAppsandLogicFlows, PowerBI, PowerBIPro, PowerBIFree, RMSAdhoc

    .EXAMPLE
        Adds the base set of options (predefined by I.T.) to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        $Users = Import-CSV .\UserList.CSV
        $Users | Set-365License

    .EXAMPLE
        Adds the base set of options to a list of Office 365 user(s) from a filtered list of Get-MsolUser
        
        $Users = Get-MsolUser -Department "Human Resources"
        $Users | Set-365License

    .EXAMPLE
        Adds the SKUs E3 and EMS (with all options) to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)
        
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-365License -E3 -EMS

    .EXAMPLE
        Adds the SKUs E3 and EMS (both, with all options) then removes the option "Flow" from a list of Office 365 user(s)
        
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-365License -E3 -EMS -RemoveOption Flow

    .EXAMPLE
        Adds the 3 options "Microsoft Teams, Sway & Flow" to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)
        
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-365License -AddOption Teams -AddOption2 Sway -AddOption3 Flow

    .EXAMPLE
        Removes the option "Microsoft Sway" from a list of Office 365 user(s) from a CSV of UserPrincipalName(s)
        
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-365License -RemoveOption Sway
   
    .EXAMPLE
        Removes the SKUs E3 and EMS from a list of Office 365 user(s) from a CSV of UserPrincipalName(s)
        
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-365License -E3 -EMS -RemoveSKU
   
#>  
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    Param
    (
        # Users to be licensed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Users,

        [Parameter(Mandatory = $False)]
        [switch] $E3,
 
        [parameter(Mandatory = $False)]
        [switch] $E5,
          
        [parameter(Mandatory = $False)]
        [switch] $EMS,
         
        [parameter(Mandatory = $False)]
        [switch] $RemoveSKU,
 
        [parameter(Mandatory = $False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "Intune", "Azure_Info_Protection", "Azure_AD_Premium", "Azure_Rights_Mgt", "Azure_MultiFactorAuth")]
        [string] $AddOption,

        [parameter(Mandatory = $False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "Intune", "Azure_Info_Protection", "Azure_AD_Premium", "Azure_Rights_Mgt", "Azure_MultiFactorAuth")]
        [string] $AddOption2,
         
        [parameter(Mandatory = $False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "Intune", "Azure_Info_Protection", "Azure_AD_Premium", "Azure_Rights_Mgt", "Azure_MultiFactorAuth")]
        [string] $AddOption3,
 
        [parameter(Mandatory = $False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "Intune", "Azure_Info_Protection", "Azure_AD_Premium", "Azure_Rights_Mgt", "Azure_MultiFactorAuth")]
        [string] $RemoveOption,

        [parameter(Mandatory = $False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "Intune", "Azure_Info_Protection", "Azure_AD_Premium", "Azure_Rights_Mgt", "Azure_MultiFactorAuth")]
        [string] $RemoveOption2,

        [parameter(Mandatory = $False)]
        [ValidateSet("Teams", "Sway", "Yammer", "Flow", "OfficePro", "StaffHub", "Planner", "PowerApps", "AzureRMS", "OfficeOnline", "SharePoint", "Skype", "Exchange", "Intune", "Azure_Info_Protection", "Azure_AD_Premium", "Azure_Rights_Mgt", "Azure_MultiFactorAuth")]
        [string] $RemoveOption3,
  
        [Parameter(Mandatory = $False)]
        [switch] $PowerAppsandLogicFlows,
 
        [parameter(Mandatory = $False)]
        [switch] $PowerBI,
         
        [parameter(Mandatory = $False)]
        [switch] $PowerBIPro,

        [parameter(Mandatory = $False)]
        [switch] $PowerBIFree,
                 
        [parameter(Mandatory = $False)]
        [switch] $RMSAdhoc,

        [Parameter()]
        [string] $ErrorLog = $LogPreference
    )

    # Function's Begin Block
    Begin {

        # Zero Variables and Define Arrays
        $BaseDisabledOptions = @()
        $BaseSkuRemove = @()
        $addsku = @()
        $addop = @()
        $remop = @()
        $user = @()
        $numadd = 0 
        $numrem = 0
        $numsku = 0
        $numbase = 0

        # Assign Tenant and Location to a variable
        $Tenant = (Get-MsolAccountSku).accountname
        $Location = "US"

        # Set Base Disabled Options for SKU    
        $BaseDisabledOptions = 'OFFICESUBSCRIPTION'
        $PrimarySku = $SkuE3
       
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
        
        # Start Transcript of PowerShell Session
        Start-Transcript -Path '.\Office365_PowerShell.txt' -Append
        
        # Hashtable for Options
        $hash = @{ 
            "Teams"                 = "TEAMS1";
            "Sway"                  = "SWAY";
            "Yammer"                = "YAMMER_ENTERPRISE";
            "Flow"                  = "FLOW_O365_P2";       
            "OfficePro"             = "OFFICESUBSCRIPTION";
            "StaffHub"              = "Deskless";
            "Planner"               = "PROJECTWORKMANAGEMENT";
            "PowerApps"             = "POWERAPPS_O365_P2";
            "AzureRMS"              = "RMS_S_ENTERPRISE";
            "OfficeOnline"          = "SHAREPOINTWAC";
            "SharePoint"            = "SHAREPOINTENTERPRISE";
            "Skype"                 = "MCOSTANDARD";
            "Exchange"              = "EXCHANGE_S_ENTERPRISE";
            "Intune"                = "INTUNE_A";
            "Azure_Info_Protection" = "RMS_S_PREMIUM";
            "Azure_Rights_Mgt"      = "RMS_S_ENTERPRISE";
            "Azure_AD_Premium"      = "AAD_PREMIUM";
            "Azure_MultiFactorAuth" = "MFA_PREMIUM"
        }

        # Hashtable to match Options to their SKUs
        $hash4sku = @{ 
            "Teams"                 = "$SkuE3";
            "Sway"                  = "$SkuE3";
            "Yammer"                = "$SkuE3";
            "Flow"                  = "$SkuE3";
            "OfficePro"             = "$SkuE3";
            "StaffHub"              = "$SkuE3";
            "Planner"               = "$SkuE3";
            "PowerApps"             = "$SkuE3";
            "AzureRMS"              = "$SkuE3";
            "OfficeOnline"          = "$SkuE3";
            "SharePoint"            = "$SkuE3";
            "Skype"                 = "$SkuE3";
            "Exchange"              = "$SkuE3";
            "Intune"                = "$SkuEMS";
            "Azure_Info_Protection" = "$SkuEMS";
            "Azure_Rights_Mgt"      = "$SkuEMS";
            "Azure_AD_Premium"      = "$SkuEMS";
            "Azure_MultiFactorAuth" = "$SkuEMS"
        }

        # Check if SKUs are to be modified
        if ($E3.IsPresent) {
            $numsku++
            $addsku += $SkuE3
        }
        if ($E5.IsPresent) {
            $numsku++
            $addsku += $SkuE5
        }
        if ($EMS.IsPresent) {
            $numsku++
            $addsku += $SkuEMS
        }
        if ($PowerAppsandLogicFlows.IsPresent) {
            $numsku++
            $addsku += $SkuPowerApps
        }
        if ($PowerBI.IsPresent) {
            $numsku++
            $addsku += $SkuPowerBI
        }
        if ($PowerBIPro.IsPresent) {
            $numsku++
            $addsku += $SkuPowerBIPro
        }
        if ($PowerBIFree.IsPresent) {
            $numsku++
            $addsku += $SkuPowerBIFree
        }
        if ($RMSAdhoc.IsPresent) {
            $numsku++
            $addsku += $SkuRMSAdhoc
        }
        
        # Compile a list of Options to be added
        if ($AddOption) {
            $numadd++
            $addop += $AddOption
        }
        if ($AddOption2) {
            $numadd++            
            $addop += $AddOption2
        }
        if ($AddOption3) {
            $numadd++
            $addop += $AddOption3        
        }

        # Compile a list of Options to be removed
        if ($RemoveOption) {
            $numrem++
            $remop += $RemoveOption
        }
        if ($RemoveOption2) {
            $numrem++
            $remop += $RemoveOption2
        }
        if ($RemoveOption3) {
            $numrem++
            $remop += $RemoveOption3
        }

        # Compile Base Options
        if (!($numsku -or $numadd -or $numrem)) {
            $BaseSkuRemove += , $SkuEO2
            $BaseSkuRemove += , $SkuE2
            $BaseSkuRemove += , $SkuE1            
            $BaseSkuRemove += , $SkuShareEnt
        }
    }

    Process {
        $DisabledOptions = @()      

        # Compile all user's attributes from UPN
        $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName

        # Set User's Location
        Set-MsolUser -UserPrincipalName $user.userprincipalname -UsageLocation $Location

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
        if ((Get-MsolAccountSku |where {$_.accountskuid -eq $PrimarySku}).consumedunits -lt (Get-MsolAccountSku |? {$_.accountskuid -eq $PrimarySku}).activeunits) {
            if ($BaseSkuRemove) {
                for ($i = 0; $i -lt $BaseSkuRemove.count; $i++) {
                    if ($user.licenses.accountskuid -match $BaseSkuRemove[$i]) {
                        Write-Output "$($user.userprincipalname) is assigned the SKU: $($BaseSkuRemove[$i]). Removing SKU now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -RemoveLicenses $BaseSkuRemove[$i] -Verbose -ErrorAction Continue
                    }        
                }
                if ($user.licenses.accountskuid -match $PrimarySku) {
                    Write-Output "$($user.userprincipalname) is already assigned SKU: $($PrimarySku). Modifying options if necessary."
                    ForEach ($License in $user.licenses | Where {$_.AccountSkuID -eq $PrimarySku}) {
                        $License.ServiceStatus | ForEach {
                            if ($_.ServicePlan.ServiceName -eq "OFFICESUBSCRIPTION") {
                                $DisabledOptions += $_.ServicePlan.ServiceName
                            }
                        }
                    }
                    $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $PrimarySku -DisabledPlans $DisabledOptions
                    Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions -ErrorAction Continue      
                }
                else {
                    Write-Output "$($user.userprincipalname) is not assigned SKU: $($PrimarySku)`. Adding SKU with Base Options"
                    $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $PrimarySku -DisabledPlans $BaseDisabledOptions
                    Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $PrimarySku -LicenseOptions $LicenseOptions -ErrorAction Continue
                }
            }
        }
        Else {
            Write-Output "Out of $PrimarySku licenses"
            Write-Output "Exiting Script"
            exit
        }
    } #End of Process Block 
    End {
    }
}