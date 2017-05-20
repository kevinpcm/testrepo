Get-aduser -filter * -Properties * -searchBase "DC=ksldenver,DC=local" |
  select name, samaccountname, DisplayName,
  @{n="PrimarySMTP";e= {($_.proxyAddresses | ? {$_ -cmatch "SMTP*"}).Substring(5) -join ";"}},
  @{n="smtp";e= {($_.proxyAddresses | ? {$_ -cmatch "smtp*"}).Substring(5) -join ";"}},
  @{n="x500";e= {($_.proxyAddresses | ? {$_ -match "x500*"}).Substring(0) -join ";"}},
  @{n="SIP";e= {($_.proxyAddresses | ? {$_ -match "SIP*"}).Substring(4) -join ";"}} |
  Export-Csv ADUsers2.csv -NTI 
