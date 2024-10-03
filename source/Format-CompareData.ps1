# Format-CompareData.ps1
function Format-CompareData {
    [CmdletBinding()]
    param(
        $changes
    )

    # Set up constants
    $ESC = [char]27
    $reset = "$ESC[0m"
    $crossoutStop  = "$ESC[9m"
    $crossout  = "$ESC[29m"
    $underline = "$ESC[4m"
    $underlineStop = "$ESC[24m"
    $red = "$ESC[38;5;9m"
    $orange = "$ESC[38;5;202m"
    $yellow = "$ESC[38;5;11m"
    $green = "$ESC[38;5;10m"
    $white = "$ESC[38;5;15m"
    $purple = "$ESC[38;5;13m"

    $longestPath = ''

    $changes | ForEach-Object {
        if ($longestPath.length -lt $_.Path.length) {
            $longestPath = $_.Path
        }
    }

    # $longestPath | Write-Host 

    $msgTmplt = '{3}{0,14}: ' + $underline + '{1,-' + $longestPath.length + '} ' + $underlineStop + ' {2}' + $reset

    function humanFormat($value) {
        if ($value -lt 1KB) { return '{0} B ' -f ($value) }
        if ($value -lt 1MB) { return '{0:n2} KB' -f ($value / 1KB) }
        if ($value -lt 1GB) { return '{0:n2} MB' -f ($value / 1MB) }
        if ($value -lt 1TB) { return '{0:n2} GB' -f ($value / 1GB) }
        
        return '{0:n2} PB' -f ($value / 1PB)
		
    }

    $changes | ForEach-Object {
        $c = $_
        switch ($c.Op) {
            'Modified (+)' {
                $msgTmplt -f $c.Op, $c.Path, (" {0,10} -> {1,10} {2,10} bytes" -f (humanFormat($c.Item1.Length)), (humanFormat($c.Item2.Length)), ("+" +($c.Item2.Length - $c.Item1.Length)) ), $green | Write-Host
            }
            'Modified (-)' {
                $msgTmplt -f $c.Op, $c.Path, (" {0,10} -> {1,10} {2,10} bytes" -f (humanFormat($c.Item1.Length)), (humanFormat($c.Item2.Length)), ($c.Item2.Length - $c.Item1.Length) ), $orange | Write-Host
            }
            'Modified (=)' {
                $msgTmplt -f $c.Op, $c.Path, (" {2,10} ($ESC[9m{0}$ESC[29m -> {1})" -f $c.Item1.Hash, $c.Item2.Hash, (humanFormat($c.Item1.Length))), $yellow | Write-Host
            }
            'Modified (!=)' {
                $msgTmplt -f $c.Op, $c.Path, (' {2,10} ($ESC[9m{0}$ESC[29m -> {1})' -f $c.Item1.Hash, $c.Item2.Hash, (humanFormat($c.Item1.Length))), $purple | Write-Host
            }
            'Removed' {
                $msgTmplt -f $c.Op, $c.Path, (" {0,10} -> {1,10} {2,10} bytes" -f (humanFormat($c.Item1.Length)), 0, (0 - $c.Item1.Length) ), $red | Write-Host
            }
            'Added' {
                $msgTmplt -f $c.Op, $c.Path, (" {0,10} -> {1,10} {2,10} bytes" -f 0, (humanFormat($c.Item2.Length)), ("+"+$c.Item2.Length) ), $green | Write-Host
            }
            'Same' {
                $msgTmplt -f $c.Op, $c.Path, (" "), $white | Write-Host
            }
        }
    }
}
