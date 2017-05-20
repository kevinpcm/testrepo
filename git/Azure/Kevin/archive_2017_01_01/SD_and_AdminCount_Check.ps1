# This script produces an output of each ADUser's status of "Allow Inheritable Permissions to Propagate to this Object" (Or in 2012+ "Enable Inheritance")
# The output also includes the value, if any, for each ADUser's attribute "AdminCount".
# Open File in Excel, remove all rows of ADUsers that should not have their attributes modified. Re-Save.
$ADProperties = @(
	'adminCount',
	'distinguishedName',
	'canonicalName',
	'nTSecurityDescriptor',
	'proxyAddresses'
)
$ExcludeProxyAddresses = @(
	'SystemMailbox',
	'FederatedEmail',
	'HealthMailbox',
	'migration',
	'SearchMailbox',
	'DiscoverySearch',
	'Administrator',
	'MSExchApproval',
	'MsExchDiscovery'
)
$LdapFilter = '(&' + '(proxyaddresses=*)' + (-join ($ExcludeProxyAddresses | % {"(!(proxyaddresses=*$($_)*))"})) + ')'

Get-ADUser -LdapFilter $LdapFilter -Properties $ADProperties -ResultSetSize 1000000 |
	Select-Object -Property `
		@{Name='dn'; Expression={$_.distinguishedName}},
		@{Name='InheritenceNeedsToBeEnabled'; Expression={$_.nTSecurityDescriptor.AreAccessRulesProtected}},
		@{Name='adminCount'; Expression={$_.adminCount}},
		@{Name='OU'; Expression={([IO.Path]::GetDirectoryName($_.canonicalName)).Replace('\', '/')}} |
	Sort-Object -Property canonicalName |
	Export-Csv -Path c:\scripts\IsInheritanceEnabled.csv -NoTypeInformation -Encoding ASCII