Get-aduser -filter * -searchBase "OU=CORP,DC=corp,DC=ad,DC=sentara1,DC=com " | select samaccountname | Export-Csv SamAccountName.csv -NTI
