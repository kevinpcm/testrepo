
param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "kevin@thenext.net",
    [parameter(Mandatory=$False)] [string] $azTenId    = "ffefc0c4-2ef8-49f8-a251-907971968a26",
    [parameter(Mandatory=$False)] [string] $azSubId    = "d2fc1b6f-162c-4553-b423-6c8b9902819e",
    [parameter(Mandatory=$False)] [string] $InputFile  = "godc.csv"
)
    $azCred = Login-AzureRmAccount -SubscriptionId $azSubId -Tenant $azTenId
Login-AzureRmAccount
Save-AzureRmProfile -Path .\profile1.json -Force
Select-AzureRmProfile -Path .\profile1.json