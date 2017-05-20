# If there are no "Available" PSSession's, execute this function
function Connect-Office365 {

    $SessionAvailable = Get-PSSession | Where {$_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.Availability -eq 'available'}
    if (!($SessionAvailable)) {
        <# Define Global Admin Username #>
        $adminuser = "@portofsandiego.org"

        <# Credentials #>
        $credential = Get-Credential $adminuser

        <# Office 365 Tenant #>
        Import-Module MsOnline
        Connect-MsolService -Credential $credential

        <# Exchange Online #>
        $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
        Import-PSSession $exchangeSession -DisableNameChecking
    }
}
