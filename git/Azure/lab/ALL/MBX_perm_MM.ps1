$OutFile = "C:\scripts\PermissionExport.txt" 
"DisplayName" + "," + "Alias" + "," + "Primary SMTP" + "," + "Full Access" + "," + "Send As" + "," + "Send on Behalf" | Out-File $OutFile -Force 

$Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select Identity, Alias, DisplayName, DistinguishedName, primarysmtpaddress 
ForEach ($Mailbox in $Mailboxes) 
{ 
       $SendAs = Get-ADPermission $Mailbox.DistinguishedName | ? {$_.ExtendedRights -like "Send-As" -and $_.User -notlike "NT AUTHORITY\SELF" -and !$_.IsInherited} | % {$_.User}
       $SendAs| % {$array += $SendAs.($_.Identity)}
       $array | %{$uSendAs += ($(if($uSendAs){";"}) + (Get-mailbox $_ | Select primarysmtpaddress))}
       $FullAccess = Get-MailboxPermission $Mailbox.Identity | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User}
       $FullAccess | %{$uFullAccess += ($(if($uFullAccess){";"}) + $_.identity)}
       $sendbehalf = Get-Mailbox $Mailbox.Identity | select-object -expand grantsendonbehalfto | select-object -expand rdn | % {$_.User}
       $sendbehalf | %{$usendbehalf += ($(if($usendbehalf){";"}) + $_.identity)}
       if (!$uSendAs -and !$FullAccess -and !$sendbehalf){continue}
       $Mailbox.DisplayName + "," + $Mailbox.Alias + "," + $Mailbox.primarysmtpaddress + "," + $FullAccess + "," + $uSendAs + "," + $sendbehalf | Out-File $OutFile -Append 
 }  

 $person | get-member -MemberType Property | % {$array += $person.($_.Name)}