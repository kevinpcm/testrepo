Get-WindowsFeature | select select displayname,name,installstate,@{Name='DependsOn';Expression={[string]::join(“;”, ($_.DependsOn))}} | export-csv c:\scripts\IISservercomponents4.csv -nti
