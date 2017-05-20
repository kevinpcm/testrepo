$cputhreshold = 0
$computers = "kevin"
$computers |
    ForEach-Object {
    $computer = $_
    Get-Counter "\\$computer\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 |
        Select -Expand CounterSamples |
        Select -Expand CookedValue |
        Measure-Object -Average |
        where { $_.Average -gt $cputhreshold } |
        Select @{n = 'ComputerName'  ; e = {$computer}},
               @{n = 'CPUUtilization'; e = {'{0:N2}' -f $_.Average}}
} | ConvertTo-HTML -fragment