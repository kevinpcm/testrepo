   Get-ADDomain | Export-CSV $LogFile-ADDomain.csv -NoTypeInformation
   Get-ADUser  -filter * -properties * | Export-CSV $LogFile-ADUsers.csv -NoTypeInformation
   Get-ADComputer  -filter * -properties * | Export-CSV $LogFile-ADComputers.csv -NoTypeInformation
   Get-ADGroup  -filter * -properties * | Export-CSV $LogFile-ADGroups.csv -NoTypeInformation
   #
   Get-ADUser  -filter 'AdminCount -eq 1' -Properties MemberOf | Select DistinguishedName,Enabled,GivenName,Name,SamAccountName,SID,Surname,ObjectClass,@{name="MemberOf";expression={$_.memberof -join "'n"}},ObjectGUID,UserPrincipalName|Export-Csv $logfile-ADUsers-Admin.csv -NoTypeInformation
   Get-ADGroup  -filter 'AdminCount -eq 1' -Properties Members | Select DistinguishedName,GroupCategory,GroupScope,Name,SamAccountName,ObjectClass,@{name="Members";expression={$_.members -join "'n"}},ObjectGUID,SID |Export-Csv $logfile-ADGroups-Admin.csv -NoTypeInformation
   