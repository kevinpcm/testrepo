param (
    [parameter(Mandatory=$False)] [string] $InputFile  = "JoinDomain.csv"
)

$csvData = Import-Csv $InputFile

if ($csvData -ne $null) {

    foreach ($row in $csvData) {
		$vmName     = $row.Name
        $Domain     = $row.Domain
        $OrgUnit    = $row.OrgUnit

JoinDomain -ConfigurationData $ConfigData -MachineName $vmName -credential (Get-Credential) -Domain $Domain
    }
}   