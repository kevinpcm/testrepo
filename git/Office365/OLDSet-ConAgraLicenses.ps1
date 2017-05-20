#>
function Set-ConAgraLicenses {
    [CmdletBinding()]
    Param
    (
        # Users to be licensed
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]] $Users,

        [Parameter(parametersetname="E3")]
        [switch]$E3,
 
        [Parameter(parametersetname="EMS")]
        [switch]$EMS,
 
        [Parameter(parametersetname="Power BI Pro")]
        [switch]$PowerBIPro,
 
        [Parameter(parametersetname="Power BI Individual User")]
        [switch]$PowerBIIndividual,
 
        [Parameter(parametersetname="Power BI Standard/Free")]
        [switch]$PowerBIFree,
 
        [Parameter(parametersetname="Rights Management ADHOC")]
        [switch]$RMSAdhoc

    )

    Begin {
        # Assign Tenant and Location to a variable
        $Tenant     = "cagrecipe"
        $Location   = "US"
        
        # Assign each AccountSkuID to a variable
        $TenantE3      = ($Tenant + ':ENTERPRISEPACK')
        $TenantEMS     = ($Tenant + ':EMS')
        $TenantProBI   = ($Tenant + ':POWER_BI_PRO')
        $TenantIUserBI = ($Tenant + ':POWER_BI_INDIVIDUAL_USER')
        $TenantFreeBI  = ($Tenant + ':POWER_BI_STANDARD')
        $TenantRMS     = ($Tenant + ':RIGHTSMANAGEMENT_ADHOC')              
        
        # Assign each License Options to a variable and zero counter
        $i = 0

        if($E3.IsPresent){
            $LicenseE3 = New-MsolLicenseOptions -AccountSkuId $TenantE3
            $Options += $LicenseE3
        }
        if($EMS.IsPresent){
            $LicenseEMS = New-MsolLicenseOptions -AccountSkuId $TenantEMS
            $Options += $LicenseEMS
        }
        if($PowerBIPro.IsPresent){
            $LicenseProBI = New-MsolLicenseOptions -AccountSkuId $TenantProBI
            $Options += $LicenseProBI
        }
        if($PowerBIIndividual.IsPresent){
            $LicenseIUserBI = New-MsolLicenseOptions -AccountSkuId $TenantIUserBI
            $Options += $LicenseIUserBI
        }
        if($PowerBIFree.IsPresent){
            $LicenseFreeBI = New-MsolLicenseOptions -AccountSkuId $TenantFreeBI
            $Options += $LicenseFreeBI
        }
        if($RMSAdhoc.IsPresent){
            $LicenseRMS = New-MsolLicenseOptions -AccountSkuId $TenantRMS
            $Options += $LicenseRMS
        }
        
    }
    Process {

        Set-MsolUser -UserPrincipalName $_.UserPrincipalName -UsageLocation $Location
        Set-MsolUserLicense -Verbose -UserPrincipalName $_.UserPrincipalName -AddLicenses -LicenseOptions
    
    }
    End {
    }
}