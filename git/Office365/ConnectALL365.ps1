function Connect-Office365 
{
    <# Credentials #>
    $credential = Get-Credential "admin@sent.onmicrosoft.com"

    <# Office 365 Tenant #>
    Import-Module MsOnline
    Connect-MsolService -Credential $credential

    <# SharePoint Online #>
    Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
    Connect-SPOService -Url https://sent-admin.sharepoint.com -credential $credential

    <# Skype For Business Online #>
    Import-Module SkypeOnlineConnector
    $sfboSession = New-CsOnlineSession -Credential $credential -OverrideAdminDomain "sent.onmicrosoft.com"
    Import-PSSession $sfboSession -AllowClobber

    <# Exchange Online #>
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
    Import-PSSession $exchangeSession -DisableNameChecking

    <# Office 365 Compliance #>
    $ccSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.compliance.protection.outlook.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
    Import-PSSession $ccSession -Prefix cc

}
Connect-Office365