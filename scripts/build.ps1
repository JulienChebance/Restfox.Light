param (
	[string]$productName = "web2exe"
)

Write-Host "🔧 Starting C# compilation with web2exe..."

# Remove unauthorized characters
$productName = $productName -replace "[:/\\?]", ""

# Gzip files
$extensions = @(".html", ".css", ".js", ".json", ".mjs", ".svg", ".ttf", ".txt", ".woff2")
Get-ChildItem -Recurse -File -Exclude "LICENSE.txt" | Where-Object {
	$extensions -contains $_.Extension.ToLower()
} | ForEach-Object {
	$inputFile = $_.FullName
	$outputFile = "$inputFile.gz"

	$inputStream = [System.IO.File]::OpenRead($inputFile)
	$outputStream = [System.IO.File]::Create($outputFile)
	$gzipStream = New-Object System.IO.Compression.GzipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
	$inputStream.CopyTo($gzipStream)

	$gzipStream.Dispose()
	$outputStream.Dispose()
	$inputStream.Dispose()
	Remove-Item $inputFile -Force
}

# Collect resources (all non-exe, non-cs, non-bat files)
$resources = '/res:' + ((Get-ChildItem -Recurse -Exclude '*.exe', '*.cs', '*.bat' -File -Name | Select-String -Pattern '^\.' -NotMatch | ForEach-Object { '"' + $_ + '"' -replace '\\', '/' }) -Join ' /res:')
Write-Host "📦 Loaded resources: $resources"

$icon = (Test-Path ".\favicon.ico") ? "/win32icon:favicon.ico" : ""
$csFiles = (Get-ChildItem -Filter *.cs | ForEach-Object { $_.FullName }) -join ' '
Invoke-Expression "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe -out:`"$productName.exe`" $csFiles -optimize -nologo $icon $resources"

if ($LASTEXITCODE -eq 0) {
	Write-Host "✅ Compilation successful: $productName.exe"
} else {
	Write-Error "❌ CSC compilation failed with exit code $LASTEXITCODE"
}