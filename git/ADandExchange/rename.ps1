$path = Split-Path -parent $MyInvocation.MyCommand.Definition 
 
Function renameFiles 
{ 
  # Loop through all directories 
  $dirs = dir $path -Recurse | Where { $_.psIsContainer -eq $true } 
  Foreach ($dir In $dirs) 
  { 
    # Set default value for addition to file name 
    $i = 1 
    $newdir = $dir.name + "_" 
    # Search for the files set in the filter (*.jpg in this case) 
    $files = Get-ChildItem -Path $dir.fullname -Filter *.csv -Recurse 
    Foreach ($file In $files) 
    { 
      # Check if a file exists 
      If ($file) 
      { 
        # Split the name and rename it to the parent folder 
        $split    = $file.name.split(".csv") 
        $replace  = $split[0] -Replace $split[0],($newdir + $i + ".csv") 
 
        # Trim spaces and rename the file 
        $image_string = $file.fullname.ToString().Trim() 
        "$split[0] renamed to $replace" 
        # Rename-Item "$image_string" "$replace" 
        $i++ 
      } 
    } 
  } 
} 
# RUN SCRIPT 
renameFiles 
"SCRIPT FINISHED"