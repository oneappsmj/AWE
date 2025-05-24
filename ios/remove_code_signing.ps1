# PowerShell script to modify project.pbxproj for simulator use without code signing

$projectFile = "Runner.xcodeproj/project.pbxproj"

# Check if the file exists
if (!(Test-Path $projectFile)) {
    Write-Error "Error: project.pbxproj file not found at $projectFile"
    exit 1
}

# Read the project file
$content = Get-Content $projectFile -Raw

# Remove code signing requirements
$content = $content -replace 'DEVELOPMENT_TEAM = "CV8N38BFPJ";', 'DEVELOPMENT_TEAM = "";'
$content = $content -replace 'CODE_SIGN_STYLE = Manual;', 'CODE_SIGN_STYLE = Automatic;'
$content = $content -replace 'PROVISIONING_PROFILE_SPECIFIER = "[^"]+";', ''

# Set TARGETED_DEVICE_FAMILY to 1 (iPhone only)
$content = $content -replace 'TARGETED_DEVICE_FAMILY = "1,2";', 'TARGETED_DEVICE_FAMILY = 1;'

# Add simulator-specific settings
$debugConfig = $content -match 'Debug.xcconfig'
if ($debugConfig) {
    $content = $content -replace '("CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "iPhone Developer";)', "`$1`n`t`t`t`t""CODE_SIGN_IDENTITY[sdk=iphonesimulator*]"" = """";"
}

# Write changes back to file
Set-Content -Path $projectFile -Value $content

Write-Host "Project file updated for simulator use without code signing."
Write-Host "Next steps:"
Write-Host "1. Run: flutter build ios --simulator"
Write-Host "2. Run: flutter run -d iphone-simulator"
Write-Host ""
Write-Host "For App Store upload, you'll need to set up proper code signing in Xcode." 