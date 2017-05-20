
$AllRetentionPolies = Get-RetentionPolicy

foreach ($EachRetentionPolicy in $AllRetentionPol) {
    $EachRetentionPolicyName     = $EachRetentionPolicy.name
    $EachRetentionPolicyTagLinks = $EachRetentionPolicy.RetentionPolicyTagLinks
    foreach ($EachLink in $EachRetentionPolicyTagLinks) {
        if ($EachLink -eq $DPTName) {
            Write-Output "$EachPolicy $link"
        }
    }
}