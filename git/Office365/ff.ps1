[decimal]$cputhreshold = 1

$computers = "kevin" 
foreach ($comp in $computers) {
    get-counter -Counter "\\$comp\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 |
        select -ExpandProperty countersamples | 
        select -ExpandProperty cookedvalue | 
        Measure-Object -Average | Where-Object {$_.Average -gt $cputhreshold}
    Select @{n = 'ComputerName'  ; e = {$computer}},
    @{n = 'CPUUtilization'; e = {'{0:N2}' -f $_.Average}}
} # | ConvertTo-HTML -Fragment