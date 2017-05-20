<# 
expects CSV with header "immutableid" without quotes
#>
$immutableId = $args[0]
$tenant = "@pyrotek.onmicrosoft.com"
$ids = Import-Csv .\immutableids.csv

foreach ($id in $ids)
    {
    $user = Get-MsolUser -All  | where {$_.ImmutableId -eq $id.ImmutableId}

    $newUPN = "_temp_"+$user.UserPrincipalName.SubString(0,$user.UserPrincipalName.IndexOf("@"))+$tenant

    Write-Host "Current UPN:" $user.UserPrincipalName
    Write-Host "Changed To: " $newUPN

    Set-MsolUserPrincipalName -UserPrincipalName $user.UserPrincipalName -NewUserPrincipalName $newUPN -whatif | Out-Null

    }