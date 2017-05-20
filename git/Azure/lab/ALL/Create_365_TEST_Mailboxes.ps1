$numberofMailboxes = Read-Host "Enter the Number of Mailboxes you want"
$EnterPrefix = Read-Host "Enter the Prefix of the Account"
$Password = Convertto-SecureString "Tote2830" -Asplaintext -Force
$GettingEmailSuffix = "sentara1.com"
$mail = "@"+"$GettingEmailSuffix"
$ou = "OU=USERS,OU=CORP,DC=corp,DC=ad,DC=sentara1,DC=com"

$array = @()
$array += "UserPrincipalName"

    For($i=0;$i -le $numberofMailboxes;$i++)
{
if ($i -ne "0")
    {
    $ii = $i.ToString("00")
    $UPN = "$EnterPrefix"+"$ii"+"$mail"
    $Name = "$EnterPrefix"+"$ii"
    $array += $upn
    New-RemoteMailbox -UserPrincipalName $UPN -Alias $Name -Name $Name -DisplayName $Name -OnPremisesOrganizationalUnit $ou -Password $Password -ResetPasswordOnNextLogon $false
    }
}
$array | Out-File "C:\scripts\licenseme.csv"