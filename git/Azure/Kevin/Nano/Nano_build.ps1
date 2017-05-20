# Change Working Directory
cd C:\NanoServer

# Import Module
Import-Module .\NanoServerImageGenerator.psm1

# Create Nano Server Image VHDX
New-NanoServerImage -MediaPath .\Files -BasePath .\Base -TargetPath .\Images\NanoVMGA.vhdx -MaxSize 20GB -DeploymentType Guest -Edition Datacenter -ComputerName "Nano01"