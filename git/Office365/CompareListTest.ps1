# Input Files
$goodpath = '.\good.txt'
$good = Get-Content $goodpath
$all = Get-MsolUser -All | ? {$_.IsLicensed -eq 'True'}

# Build List of Comparison

ForEach ($row in $all | Where {$good -notcontains $_.UserPrincipalName}) {
    Write-Output $row
}





<#
# Input Files
$goodpath = '.\good.csv'
$good = Import-Csv $goodpath -Header upn
$all = Get-MsolUser -All | ? {$_.IsLicensed -eq 'True'}

# Build List of Comparison

$all | where {$_.UserPrincipalName -notcontains $good.upn} | %  {
    $row = $_
    Write-Output $row
    # Write-Output "Rows: $($row.UserPrincipalName)"
    # Write-Output "Good: $good"
}
#>