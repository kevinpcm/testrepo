$Script:var = "SCRIPT"

function test {
    $var = "FUNCTION"
    "Testing `$Global:var = $Global:var"
    "Testing `$script:var = $Script:var"
    "Testing `$var = $var"
}

test
$var


