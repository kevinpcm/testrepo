$Report = @()
$GroupCollection = Get-ADGroup -Filter * | select Name,MemberOf,ObjectClass,SAMAccountName,sid

Foreach($Group in $GroupCollection){
$MemberGroup = Get-ADGroupMember -Identity $Group.SAMAccountName | where{$_.ObjectClass -eq ‘group’}
$MemberGroups = ($MemberGroup.Name) -join “`r`n”
if($MemberGroups -ne “”){
$Out = New-Object PSObject
$Out | Add-Member -MemberType noteproperty -Name ‘Member Groups’ -Value $MemberGroups

    $Report += $Out
}
}
$membergroupnames = $Report