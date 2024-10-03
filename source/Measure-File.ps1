function Measure-File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.IO.FileInfo]$File,
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [String]$HashAlgorithm = 'MD5'
    )

    process {
        return @{
            FullName      = $File.FullName
            Hash          = (Get-FileHash -Algorithm $HashAlgorithm -Path $File.FullName).Hash
            Length        = $File.Length
            LastWriteTime = $File.LastWriteTime
            MeasureTaken  = [datetime]::Now
        }
    }
}