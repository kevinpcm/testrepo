 Set-ADServerSettings -ViewEntireForest $true
 $users = Import-Csv c:\scripts\sAMAccountname.csv
  
 foreach($row in $users){

  
 $user = get-mailbox $row.samaccountname 
 $user.EmailAddresses | Where-Object{$_.AddressString -like '*@sentara1.com'}| ForEach-Object{
 
 Set-mailbox $user.samaccountname -EmailAddressPolicyEnabled $false -whatif
 Set-mailbox $user.samaccountname -EmailAddresses @{remove=$_} -whatif
 # Set-mailbox $user.samaccountname -EmailAddressPolicyEnabled $true -whatif
  
    }
  
 }