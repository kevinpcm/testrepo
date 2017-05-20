
    $credential = Get-Credential "admin@sent.onmicrosoft.com"

    <# Office 365 Tenant #>
    Import-Module MsOnline
    Connect-MsolService -Credential $credential
