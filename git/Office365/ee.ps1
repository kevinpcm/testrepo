$object = New-Object –TypeName PSObject
$allmoves = Get-MoveRequest -ResultSize Unlimited
Foreach ($user in $allmoves) {
        $usermove = Get-moverequest -identity $user
        $object | Add-Member -MemberType NoteProperty -Name DisplayName -Value $user.DisplayName
        $object | Add-Member -MemberType NoteProperty -Name UPN -Value $user.userprincipalname
        $object | Add-Member -MemberType NoteProperty -Name CompletionTime -Value $usermove.CompletionTimestamp
}
$object | Export-csv testmoves.csv -NoTypeInformation