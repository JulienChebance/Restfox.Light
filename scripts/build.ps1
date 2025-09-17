param (
	[string]$productName = "web2exe"
)

Write-Host "🔧 Starting C# compilation with web2exe..."

# Remove unauthorized characters
$productName = $productName -replace "[:/\\?]", ""

# Collect resources (all non-exe, non-cs, non-bat files)
$resources = '/res:' + ((Get-ChildItem -Path .\ -Recurse -Exclude '*.exe', '*.cs', '*.bat' -File -Name | Select-String -Pattern '^\.' -NotMatch | ForEach-Object { '"' + $_ + '"' -replace '\\', '/' }) -Join ' /res:')
Write-Host "📦 Loaded resources: $resources"

$icon = (Test-Path ".\favicon.ico") ? "/win32icon:favicon.ico" : ""
$csFiles = (Get-ChildItem -Filter *.cs | ForEach-Object { $_.FullName }) -join ' '
Invoke-Expression "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe -out:`"$productName.exe`" $csFiles -optimize -nologo $icon $resources"

if ($LASTEXITCODE -eq 0) {
	Write-Host "✅ Compilation successful: $productName.exe"
} else {
	Write-Error "❌ CSC compilation failed with exit code $LASTEXITCODE"
}