param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "kevin@thenext.net",
    [parameter(Mandatory=$False)] [string] $azTenId    = "ffefc0c4-2ef8-49f8-a251-907971968a26",
    [parameter(Mandatory=$False)] [string] $azSubId    = "d2fc1b6f-162c-4553-b423-6c8b9902819e",
    [parameter(Mandatory=$False)] [string] $InputFile  = "godc.csv"
)
$csvData = Import-Csv $InputFile
$csv4ltr = $csvData
function WaitforAllRunning($vmName)
        {
        do {
            Start-Sleep -milliseconds 100
            $vmStatuses  = Get-AzureRmVM -VM $vmName -ResourceGroupName $rgName -Status | select -ExpandProperty Statuses | Select -ExpandProperty DisplayStatus
            $vmStatus    = $VMStatuses[1]
            } 
            until ($VMStatus -eq 'VM running')
        }
foreach ($row in $csv4ltr)
    {
    $vmName  = $row.name
    $rgName  = $row.ResourceGroup    
    Write-Output "Azure VM: $vmName"
    WaitforAllRunning -vm $vmName
    }
Write-Output "COMPLETE"