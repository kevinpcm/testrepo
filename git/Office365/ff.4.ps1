$tableFragment = Get-WMIObject  -ComputerName localhost win32_processor | 
    select __Server, @{name = "CPUUtilization" ; expression = {{0:N2} -f (get-counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 |
                select -ExpandProperty countersamples)}
    }
    Write-Output $tableFragment

Write-Output {0:N2} -f (get-counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 | select -ExpandProperty countersamples)