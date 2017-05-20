param (
    [parameter(Mandatory=$False)] [string] $azEnv      = "AzureCloud",
    [parameter(Mandatory=$False)] [string] $azAcct     = "kevin.blumenfeld@pcm.com",
    [parameter(Mandatory=$False)] [string] $azTenId    = "9398aae1-94ce-4c6b-bda0-4ebd3c78df86",
    [parameter(Mandatory=$False)] [string] $azSubId    = "241b09aa-8028-4a27-9e25-fc560a928624",
    [parameter(Mandatory=$False)] [string] $InputFile  = "Answer_qa__Add_Domain_Controllers.csv"
)

Write-Output "checking if session is authenticated..."
if ($azCred -eq $null) {
    Write-Output "authentication is required."
    $azCred = Login-AzureRmAccount -EnvironmentName $azEnv -AccountId $azAcct -SubscriptionId $azSubId -TenantId $azTenId
}
else {
    Write-Output "authentication already confirmed."
}
