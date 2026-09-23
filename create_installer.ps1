# PowerShell script to package Reconix Release/Executable Build into Windows Installer Wizard
$possibleDirs = @(
    "c:\flutter_projects\reconix\build\windows\x64\runner\Release",
    "c:\flutter_projects\reconix\build\windows\x64\runner\Debug",
    "c:\flutter_projects\reconix\build\windows\runner\Release"
)

$releaseDir = $null
foreach ($dir in $possibleDirs) {
    if (Test-Path "$dir\reconix.exe") {
        $releaseDir = $dir
        break
    }
}

if (-not $releaseDir) {
    Write-Host "Executable build directory containing reconix.exe not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found executable package at: $releaseDir" -ForegroundColor Green

# Copy Visual C++ Runtime DLLs to release directory to prevent VCRUNTIME140_1.dll missing errors on target machines
$vcDlls = @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll", "msvcp140_codecvt_ids.dll")
foreach ($dll in $vcDlls) {
    $sysPath = "C:\Windows\System32\$dll"
    if (Test-Path $sysPath) {
        Copy-Item -Path $sysPath -Destination "$releaseDir\$dll" -Force
        Write-Host "Bundled $dll into release package" -ForegroundColor Gray
    }
}

$outputDir = "c:\flutter_projects\reconix\build\installer"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Update Inno Setup script with actual directory
$issContent = Get-Content "c:\flutter_projects\reconix\reconix_installer.iss" -Raw
$updatedIssContent = $issContent -replace 'Source: "build\\windows\\x64\\runner\\Release\\\*"', "Source: `"$releaseDir\*`""
Set-Content -Path "c:\flutter_projects\reconix\reconix_installer.iss" -Value $updatedIssContent

# Check for Inno Setup Compiler
$isccPaths = @(
    "iscc.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:LocalAppData}\Programs\Inno Setup 6\ISCC.exe"
)

$isccPath = $null
foreach ($path in $isccPaths) {
    $cmd = Get-Command $path -ErrorAction SilentlyContinue
    if ($cmd) {
        $isccPath = $cmd.Source
        break
    } elseif (Test-Path $path) {
        $isccPath = $path
        break
    }
}

if ($isccPath) {
    Write-Host "Found Inno Setup Compiler at: $isccPath" -ForegroundColor Green
    Write-Host "Compiling Windows Setup Wizard executable..." -ForegroundColor Yellow
    & $isccPath "c:\flutter_projects\reconix\reconix_installer.iss"
    Write-Host "Successfully compiled Windows Installer Wizard at $outputDir\Reconix_Setup_v1.0.0.exe!" -ForegroundColor Green
} else {
    Write-Host "Inno Setup Compiler (ISCC) not found in standard PATH." -ForegroundColor Yellow
    Write-Host "Creating Standalone Windows Setup Executable Package..." -ForegroundColor Yellow
    
    $zipPath = "$outputDir\Reconix_Setup_v1.0.0.zip"
    Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath -Force
    Write-Host "Created standalone installer zip archive at $zipPath" -ForegroundColor Green

    # Create 1-Click Installer PowerShell Executable script
    $installerScript = @"
# Reconix 1-Click Windows Setup Wizard
Write-Host '===================================================' -ForegroundColor Cyan
Write-Host '   Installing Reconix VAT Platform for Windows   ' -ForegroundColor Cyan
Write-Host '===================================================' -ForegroundColor Cyan

`$installDir = "`$env:LocalAppData\Programs\Reconix"
New-Item -ItemType Directory -Force -Path `$installDir | Out-Null

Copy-Item -Path "*`" -Destination `$installDir -Recurse -Force
Write-Host "Files installed to: `$installDir" -ForegroundColor Green

# Create Desktop Shortcut
`$WshShell = New-Object -ComObject WScript.Shell
`$Shortcut = `$WshShell.CreateShortcut("`$env:USERPROFILE\Desktop\Reconix VAT Platform.lnk")
`$Shortcut.TargetPath = "`$installDir\reconix.exe"
`$Shortcut.WorkingDirectory = `$installDir
`$Shortcut.Save()

Write-Host 'Installation completed successfully!' -ForegroundColor Green
Write-Host 'Desktop Shortcut "Reconix VAT Platform" created.' -ForegroundColor Green
"@
    Set-Content -Path "$outputDir\Install_Reconix.ps1" -Value $installerScript
    Write-Host "Created Install_Reconix.ps1 setup script in $outputDir!" -ForegroundColor Green
}
