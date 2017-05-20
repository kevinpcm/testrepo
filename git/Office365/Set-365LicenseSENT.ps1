<#
    .SYNOPSIS 
        The user of this script can perform one or more of the following tasks against one or more Office 365 users:

        1.  Add a full license (SKU) with all options (ex. E3)
        2.  Add between one and three options (ex. Teams). If the user does not currently have the SKU assigned, it 
            will be added with only the option(s).
        3.  Remove between one and three option(s)
        4.  Add a "Base" set of options - Defined by I.T.:
              a.  SKU: EMS (all options)
              b.  SKU: E3 (sans these options: 'StaffHub', 'Flow', 'PowerApps', 'Teams', 'Planner', 'Sway')
        5.  Remove one or more SKU's

        Prerequisites
        
        1.  Download and install the Microsoft Online Services Sign-In Assistant
              https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi

        2.  If not running Windows 10 or higher, Install WMF 5.1 or higher
              https://www.microsoft.com/en-us/download/details.aspx?id=54616 
        
        3.  Install the Windows Azure Active Directory Module for Windows PowerShell. From an elevated PowerShell prompt run
              Install-Module -Name MSOnline
        
        4. From an elevated PowerShell prompt run:
              Set-ExecutionPolicy RemoteSigned -Force
            
    .DESCRIPTION
        Summary
                Use this function to license users for Office 365.  
                UserPrincipalName(s) are passed with a variable from the pipeline "|" to the function Set-ConAgraLicense.
        
        There are two primary methods to add a list of UPN(s) to a variable

        1.  By using a CSV (Example: $users = Import-CSV .\anylistofupns.csv)
        2.  By using Get-MsolUser and filtered parameters
              a.  Example: $users = Get-MsolUser -Department "BRM Admin"
              b.  Example: $users = Get-MsolUser -SearchString ZKB0399
              c.  For a full list of parameters on which to filter, execute this command: help Get-MsolUser -Full

        If a CSV is used
        
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

        Mandatory parameters are
            Users (ValueFromPipeline)
                
        Non-Mandatory parameters are: 
            E3, EMS, RemoveSKU, AddOption, AddOption2, AddOption3, RemoveOption, RemoveOption2, RemoveOption3, PowerAppsandLogicFlows, PowerBI, PowerBIPro, PowerBIFree, RMSAdhoc

    .EXAMPLE
        Adds the base set of options (predefined by I.T.) to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicense

    .EXAMPLE
        Adds the base set of options to a list of Office 365 user(s) from a filtered list of Get-MsolUser

        . .\Set-365Licenses.ps1
        $Users = Get-MsolUser -Department "BRM Admin"
        $Users | Set-ConAgraLicense

    .EXAMPLE
        Adds the SKUs E3 and EMS (with all options) to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicense -E3 -EMS

    .EXAMPLE
        Adds the SKUs E3 and EMS (both, with all options) then removes the option "Flow" from a list of Office 365 user(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicense -E3 -EMS -RemoveOption Flow

    .EXAMPLE
        Adds the 3 options "Microsoft Teams, Sway & Flow" to a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicense -AddOption Teams -AddOption2 Sway -AddOption3 Flow

    .EXAMPLE
        Removes the option "Microsoft Sway" from a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicense -RemoveOption Sway
   
    .EXAMPLE
        Removes the SKUs E3 and EMS from a list of Office 365 user(s) from a CSV of UserPrincipalName(s)

        . .\Set-365Licenses.ps1
        $Users = Import-CSV .\UserList.CSV
        $Users | Set-ConAgraLicense -E3 -EMS -RemoveSKU
   
#>

# Determine if a PSSession exist to Exchange Online that are "Available"
$SessionAvailable = Get-PSSession | Where {$_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.Availability -eq 'available'}

# If there are no "Available" PSSession's, execute this function
if (!($SessionAvailable)) {
    function Connect-Office365 {

        <# Define Global Admin Username #>
        $adminuser = "admin@sent.onmicrosoft.com"

        <# Credentials #>
        $credential = Get-Credential $adminuser

        <# Office 365 Tenant #>
        Import-Module MsOnline
        Connect-MsolService -Credential $credential

        <# Exchange Online #>
        $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
        Import-PSSession $exchangeSession -DisableNameChecking

    }
    Connect-Office365
}

function Set-SentLicense {
    [CmdletBinding()]
    Param
    (
        # Users to be licensed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Users,

        [Parameter(Mandatory = $False)]
        [switch] $E3,
 
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
        [switch] $RMSAdhoc
    )

    # Function's Begin Block
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

        # Assign Tenant and Location to a variable
        $Tenant = "sent"
        $Location = "US"
        
        # Assign each AccountSkuID to a variable
        $SkuE3 = ($Tenant + ':ENTERPRISEPREMIUM')
        $SkuEMS = ($Tenant + ':EMSPREMIUM')        
        $SkuPowerApps = ($Tenant + ':POWERAPPS_INDIVIDUAL_USER')
        $SkuPowerBI = ($Tenant + ':POWER_BI_INDIVIDUAL_USER')        
        $SkuPowerBIPro = ($Tenant + ':POWER_BI_PRO')
        $SkuPowerBIFree = ($Tenant + ':POWER_BI_STANDARD')        
        $SkuRMSAdhoc = ($Tenant + ':RIGHTSMANAGEMENT_ADHOC')    

        # Set Base Disabled Options for E3    
        $BaseDisabled = 'Deskless', 'FLOW_O365_P3', 'POWERAPPS_O365_P3', 'TEAMS1', 'PROJECTWORKMANAGEMENT', 'SWAY'
                
        # Start Transcript of PowerShell Session
        Start-Transcript -Path '.\SENT_Office365_PowerShell.txt' -Append

        # Hashtable for Options
        $hash = @{ 
            "Teams" = "TEAMS1";
            "Sway" = "SWAY";
            "Yammer" = "YAMMER_ENTERPRISE";
            "Flow" = "FLOW_O365_P3";       
            "OfficePro" = "OFFICESUBSCRIPTION";
            "StaffHub" = "Deskless";
            "Planner" = "PROJECTWORKMANAGEMENT";
            "PowerApps" = "POWERAPPS_O365_P3";
            "AzureRMS" = "RMS_S_ENTERPRISE";
            "OfficeOnline" = "SHAREPOINTWAC";
            "SharePoint" = "SHAREPOINTENTERPRISE";
            "Skype" = "MCOSTANDARD";
            "Exchange" = "EXCHANGE_S_ENTERPRISE";
            "Intune" = "INTUNE_A";
            "Azure_Info_Protection" = "RMS_S_PREMIUM";
            "Azure_Rights_Mgt" = "RMS_S_ENTERPRISE";
            "Azure_AD_Premium" = "AAD_PREMIUM";
            "Azure_MultiFactorAuth" = "MFA_PREMIUM"
        }

        # Hashtable to match Options to their SKUs
        $hash4sku = @{ 
            "Teams" = "$SkuE3";
            "Sway" = "$SkuE3";
            "Yammer" = "$SkuE3";
            "Flow" = "$SkuE3";
            "OfficePro" = "$SkuE3";
            "StaffHub" = "$SkuE3";
            "Planner" = "$SkuE3";
            "PowerApps" = "$SkuE3";
            "AzureRMS" = "$SkuE3";
            "OfficeOnline" = "$SkuE3";
            "SharePoint" = "$SkuE3";
            "Skype" = "$SkuE3";
            "Exchange" = "$SkuE3";
            "Intune" = "$SkuEMS";
            "Azure_Info_Protection" = "$SkuEMS";
            "Azure_Rights_Mgt" = "$SkuEMS";
            "Azure_AD_Premium" = "$SkuEMS";
            "Azure_MultiFactorAuth" = "$SkuEMS"
        }

        # Check if SKUs are to be modified
        if ($E3.IsPresent) {
            $numsku++
            $addsku += $SkuE3
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
            $basesku += $SkuE3
            $basesku += $SkuEMS
        }
    }

    Process {
        $DisabledOptions = @()      

        # Compile all user's attributes from UPN
        $user = Get-MsolUser -UserPrincipalName $_.UserPrincipalName

        # Set User's Location
        Set-MsolUser -UserPrincipalName $user.userprincipalname -UsageLocation $Location

        # Add SKUs requested by user  
        if ($numsku) {
            for ($i = 0; $i -lt $numsku; $i++) {
                $FullSku = @()
                if (!($RemoveSKU.IsPresent)) {
                    if ($user.licenses.accountskuid -match $addsku[$i]) {
                        $FullSku = New-MsolLicenseOptions -AccountSkuId $addsku[$i]
                        Write-Output "$($user.userprincipalname) already has SKU: $($addsku[$i]). All Options will be added now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $FullSku    
                    }
                    else {
                        Write-Output "$($user.userprincipalname) does not have SKU: $($addsku[$i]). Adding SKU now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $addsku[$i]
                    }
                }
                # Remove SKUs requested by user
                else {
                    if ($user.licenses.accountskuid -match $addsku[$i]) {
                        Write-Output "$($user.userprincipalname) has SKU: $($addsku[$i]). REMOVING SKU now"
                        Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -RemoveLicenses $addsku[$i] -Verbose   
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
            if ($user.licenses.accountskuid -match $SkuE3) {
                ForEach ($License in $user.licenses | Where {$_.AccountSkuID -eq $SkuE3}) {
                    $License.ServiceStatus | ForEach {
                        if ($_.ServicePlan.ServiceName -eq "Deskless" -or $_.ServicePlan.ServiceName -eq "FLOW_O365_P3" -or $_.ServicePlan.ServiceName -eq "POWERAPPS_O365_P3" -or $_.ServicePlan.ServiceName -eq "TEAMS1" -or $_.ServicePlan.ServiceName -eq "PROJECTWORKMANAGEMENT" -or $_.ServicePlan.ServiceName -eq "SWAY") {
                            $DisabledOptions += $_.ServicePlan.ServiceName
                            Write-Output "in DisOpt loop: $DisabledOptions"
                        }
                    }
                }
                Write-Output "$($user.userprincipalname) has SKU: $($SkuE3)`, verifying base options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SkuE3 -DisabledPlans $DisabledOptions
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions        
            }
            else {
                Write-Output "$($user.userprincipalname) does not have SKU: $($SkuE3)`. Adding SKU with Base Options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SkuE3 # -DisabledPlans $BaseDisabled
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $SkuE3 -LicenseOptions $LicenseOptions
            }
            if ($user.licenses.accountskuid -match $SkuEMS) {
                Write-Output "$($user.userprincipalname) has SKU: $($SkuEMS)`, verifying base options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SkuEMS
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -LicenseOptions $LicenseOptions             
            }
            else {
                Write-Output "$($user.userprincipalname) does not have SKU: $($SkuEMS)`. Adding SKU with Base Options"
                $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $SkuEMS
                Set-MsolUserLicense -UserPrincipalName $user.userprincipalname -AddLicenses $SkuEMS -LicenseOptions $LicenseOptions
            }
        }
    } #End of Process Block 
    End {
    }
}