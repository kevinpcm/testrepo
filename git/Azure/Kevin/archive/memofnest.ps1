
# Retrieve Nested Groups

$Report = @()
$GroupCollection = Get-ADGroup -Filter * | select Name,MemberOf,ObjectClass,SAMAccountName, SID

Foreach($Group in $GroupCollection){
$MemberGroup = Get-ADGroupMember -Identity $Group.SID | where{$_.ObjectClass -eq ‘group’}
$MemberGroups = ($MemberGroup.SID) -join “`r`n”
if($MemberGroups -ne “”){
$Out = New-Object PSObject
$Out | Add-Member -MemberType noteproperty -Name 'SID' -Value $MemberGroups

    $Report += $Out
}
}
Write-Output "Nested Groups... " $Report

# Retrieve Users in Nested Groups

$groups4users   = $report
Write-Output "Groups for users... " $groups4users
Foreach($row in $groups4users){
	$Ngroup     = $row.SID
Write-Output "Ngroup... " $Ngroup
	$member     = Get-ADGroupMember -Identity $NGroup | where{$_.ObjectClass -eq ‘user’}}
    $people     = ($member.SID) -join “`r`n”
if($people -ne “”){
    $peopleout  = New-Object PSObject
$peopleout | Add-Member -MemberType noteproperty -Name 'people' -Value $MemberGroups

    $peoplereport += $peopleout
}
Write-Output "peoplereport... " $peoplereport 

