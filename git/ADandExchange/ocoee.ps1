Set-DatabaseAvailabilityGroup EXCHDAG -WitnessServer CTS -WitnessDirectory C:\DAGFSW

Get-DatabaseAvailabilityGroup | Select Name,Servers,Datace*

Set-DatabaseAvailabilityGroup EXCHDAG -DatacenterActivationMode DagOnly

Set-DatabaseAvailabilityGroup -Identity EXCHDAG -AlternateWitnessDirectory C:\DAGALTFSW -AlternateWitnessServer CTS