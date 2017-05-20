            # Check Storage Account Availability
            $StorageAccountNameExists = $null
            $StNameExistsInTheTenant = $null
            $saName = $null
            # $saName = "GOSA01"
            $saName = "ivantagestorage01"
            $StorageAccountNameExists   = (Get-AzureRmStorageAccountNameAvailability -Name $saName).NameAvailable
            $StNameExistsInTheTenant    = (Get-AzureRmStorageAccount | ?{$_.StorageAccountName -eq "$saName"})
            $StNameExistsInTheTenantB   = [bool]$StNameExistsInTheTenant
            $StorageAccountNameExistsB  = [bool]$StorageAccountNameExists
            if ((!($StorageAccountNameExistsB)) -and (!($StNameExistsInTheTenantB))){
            #if ($StorageAccountNameExistsB -eq "False" -and $StNameExistsInTheTenantB -eq "False"){
                Write-Output "Storage account" $saName "name already taken"
                Write-Output "Please choose another Storage Account Name"
                Write-Output "This Powershell command can be used: Get-AzureRmStorageAccountNameAvailability -Name"
                Break
            }
            else {
                Write-Output "Storage account: $saName is either available or already yours"
                Write-Output "Name exists somewhere: $StorageAccountNameExistsB"
                Write-Output "Name exists in Tenant: $StNameExistsInTheTenantB"
            }