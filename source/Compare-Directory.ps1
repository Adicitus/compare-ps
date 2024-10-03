function Compare-Directory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=1)]
        $ReferencePath,
        [Parameter(Mandatory=$true, Position=2)]
        $DifferencePath,
        [Switch]$NoReport,
        [Switch]$ShowSame,
        [Switch]$HideRemoved,
        [Switch]$SkipAdded,
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [String]$HashAlgorithm = 'MD5',
        [String]$ExcludePattern = '\.git'
    )

    # Sanitize the inputs:
    $ReferencePath = $ReferencePath -replace '([\\]|[/])+', '\'
    if (-not $ReferencePath.endsWith('\')) { $ReferencePath += '\' }
    $DifferencePath = $DifferencePath -replace '([\\]|[/])+', '\'
    if (-not $DifferencePath.endsWith('\')) { $DifferencePath += '\' }

    $changes = [System.Collections.ArrayList]::new()

    $referenceFiles = Get-ChildItem $ReferencePath -Recurse -File | Where-Object FullName -notmatch $ExcludePattern

    # Compare existing files to the differencing directory
    $referenceFiles | ForEach-Object {
        $i1 = Measure-File $_ -HashAlgorithm $HashAlgorithm
        $p1 = $i1.FullName
        $relPath = $p1.Substring($ReferencePath.length)
        $result = @{ Path = $relPath; Item1 = $i1 }
        $changes.add($result) | out-Null
	
        $p2 = $DifferencePath + $relPath
        if (-not (Test-Path $p2)) {
            $result.Op = 'Removed'
            return
        }
	
        $i2 = Measure-File $p2 -HashAlgorithm $HashAlgorithm
        $result.Item2 = $i2
        if ($i1.LastWriteTime -ne $i2.LastWriteTime) {
            if ($i2.length -lt $i1.length) {
                $result.Op = 'Modified (-)'
                return 
            }
            if ($i2.length -gt $i1.length) {
                $result.Op = 'Modified (+)'
                return
            }
		
            if ($i1.hash -ne $i2.hash) {
                $result.Op = 'Modified (=)'
                return
            }
            else {
                $result.Op = 'Same'
            }
        }
        else {
            if ($i1.hash -ne $i2.hash) {
                $result.Op = 'Modified (!=)'
                return
            }
            else {
                $result.Op = 'Same'
                return
            }
        }
    }

    # Look for new files
    if (!$SkipAdded) {
        Get-ChildItem $DifferencePath -Recurse -File | Where-Object FullName -notmatch $ExcludePattern | ForEach-Object {
            $i2 = Measure-File $_
            $p2 = $i2.FullName
            $relPath = $p2.Substring($DifferencePath.length)
            $p1 = $ReferencePath + $relPath
            if (-not (Test-Path $p1)) {
                $result = @{ Op = 'Added'; Path = $relPath; Item2 = $i2 }
                $changes.add($result) | Out-Null
                return
            }
        }
    }

    if (-not $NoReport) {
        # Display results
        if ($HideRemoved -or (-not $ShowSame)) {
            $c = $changes
            
            if ($HideRemoved) {
                $c = $c | Where-Object Op -ne 'Removed'
            }
            if (-not $ShowSame) {
                $c = $c | Where-Object Op -ne 'Same'
            }

            Format-CompareData $c
        } else {
            Format-CompareData $changes
        }
    }

    return $changes
}