<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-License {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Users to be unlicensed
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]] $Users

    )

    Begin {
        # Zero Arrays
        $BaseDisabled = @()
        $Options = @()
        $SKU = @()

        # Assign Tenant and Location to a variable
        $Tenant     = "SENT"
        $Location   = "US"
        
        # Assign each AccountSkuID to a variable
        $TenantE3      = ($Tenant + ':ENTERPRISEPREMIUM')
        $TenantEMS     = ($Tenant + ':EMSPREMIUM')        
        
    }
    Process {
        $LicenseDetails = (Get-MsolUser -UserPrincipalName $_.UserPrincipalName).Licenses
        foreach ($License in $LicenseDetails){
            Get-MsolUser -UserPrincipalName $_.UserPrincipalName | Set-MsolUserLicense -RemoveLicenses $License.accountskuid
        }
    }
    End {
    }
}