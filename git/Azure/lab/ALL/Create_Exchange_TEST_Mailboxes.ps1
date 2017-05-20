$numberofMailboxes = Read-Host "Enter the Number of Mailboxes you want"

$EnterPrefix = Read-Host "Enter the Prefix of the Account"

$Password = Convertto-SecureString "Tote2830" -Asplaintext -Force

$GettingEmailSuffix = Read-Host "Get Email Suffix"

$GetNetBIOS = Read-Host "Get NetBIOS"

$mail = "@"+"$GettingEmailSuffix"

$ou = "OU=USERS,OU=CORP,DC=" + "$GetNetBIOS" + ",DC=ad,DC=sentara1,DC=com"

For($i=0;$i -le $numberofMailboxes;$i++)

{

if ($i -ne "0")
{
$ii = $i.ToString("00")

$UPN = "$EnterPrefix"+"$ii"+"$mail"

$Name = "$EnterPrefix"+"$ii"

New-Mailbox -Name $Name -Alias $Name -UserPrincipalName $UPN -Password $Password -organizationalunit $ou -server "se-c-ex01"
}
}