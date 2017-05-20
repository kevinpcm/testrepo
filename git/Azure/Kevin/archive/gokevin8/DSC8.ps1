configuration JoinDomain
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [string]$OrgUnit,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources
    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer JoinDomain
        {
            Name          = $NodeName
            DomainName    = $Domain
            JoinOU        = "OU=Comp,DC=gokevin8,DC=com"
            Credential    = $Credential  # Credential to join to domain

        }
    }
}

JoinDomain -MachineName $NodeName -credential (Get-Credential) -Domain $Domain
<#****************************
Install-Module xComputerManagement
NO Find-Module -DscResource xComputerManagement | Import-Module

JoinDomain -MachineName $vmName -credential (Get-Credential) -Domain $Domain

To save the credential in plain-text in the mof file, use the following configuration data

$ConfigData = @{
                 AllNodes = @(
                              @{
                                 NodeName = "localhost"
                                 # Allows credential to be saved in plain-text in the the *.mof instance document.

                                 PSDscAllowPlainTextPassword = $true
                              }
                            )
              }

JoinDomain -ConfigurationData $ConfigData -MachineName <machineName> -credential (Get-Credential) -Domain <domainName>
****************************#>