function Get-DirectoryIndex {
    param(
        [Parameter(Mandatory=$true)]
        [String]$Path,
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [String]$HashAlgorithm = 'MD5',
        [String]$ExcludePattern = '\.git'
    )

    $result = @{}

    if (-not (Test-Path $Path)) {
        $result.error = 'Missing path.'
        return $result
    }

    $rootItem = Get-Item $Path

    if ($rootItem.PSProvider.Name -ne 'FileSystem') {
        $result.error = 'Path is not in the file system.'
        return $result
    }

    if (-not $rootItem.PSIsContainer) {
        $result.error = 'Path is not a directory.'
    }

    # Sanitize the path here so that we can use it to create relative paths later:
    $rootPath = $rootItem.FullName + '\'

    $result.RootPath = $rootPath
    $result.IndexingStarted = [datetime]::Now

    $result.files = @{}
    
    Get-ChildItem $Path -Recurse -File | Where-Object FullName -NotMatch $ExcludePattern | Measure-File -HashAlgorithm $HashAlgorithm | ForEach-Object {
        $relPath = $_.FullName.Substring($rootPath.length)
        $result.files[$relPath] = $_
    }

    $result.IndexingEnded = [datetime]::Now
    return $result
}