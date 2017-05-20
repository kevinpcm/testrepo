Set-ADServerSettings -ViewEntireForest $true
$user       = $null
$alias      = $null
$newprimary = $null
$users = Import-Csv c:\scripts\sAMAccountname.csv

 foreach($row in $users)
  
    {

    $user       = get-mailbox $row.samaccountname
    $sam        = $user.samaccountname
    $alias      = $user.primarysmtpaddress.local
    $newprimary = "$alias" + "@pyrotek.com"
 
    Set-mailbox $sam -EmailAddressPolicyEnabled $false
    Set-mailbox $sam -primarysmtpaddress $newprimary
  
    }