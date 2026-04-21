# StudentMove Flutter App - Quick Run Script
# This script helps you run the Flutter app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "StudentMove Flutter App - Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "✓ Flutter is installed" -ForegroundColor Green
    Write-Host $flutterVersion[0] -ForegroundColor Gray
} catch {
    Write-Host "✗ Flutter is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Flutter first:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor White
    Write-Host "2. Extract to C:\src\flutter (or similar)" -ForegroundColor White
    Write-Host "3. Add Flutter to PATH" -ForegroundColor White
    Write-Host "4. Restart terminal and run this script again" -ForegroundColor White
    exit
}

Write-Host ""

# Navigate to project directory
Write-Host "Navigating to project directory..." -ForegroundColor Yellow
Set-Location $PSScriptRoot
Write-Host "✓ Current directory: $(Get-Location)" -ForegroundColor Green

Write-Host ""

# Get dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install dependencies" -ForegroundColor Red
    exit
}

Write-Host ""

# Check for devices
Write-Host "Checking for connected devices..." -ForegroundColor Yellow
flutter devices
Write-Host ""
Write-Host "If no devices are shown:" -ForegroundColor Yellow
Write-Host "1. Start Android Emulator from Android Studio" -ForegroundColor White
Write-Host "2. Or connect a physical Android device" -ForegroundColor White
Write-Host ""

# Ask if user wants to run
$response = Read-Host "Do you want to run the app now? (Y/N)"
if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-Host "Starting app..." -ForegroundColor Yellow
    Write-Host "Press 'r' for hot reload, 'R' for hot restart, 'q' to quit" -ForegroundColor Cyan
    Write-Host ""
    flutter run
} else {
    Write-Host ""
    Write-Host "To run the app manually, use: flutter run" -ForegroundColor Cyan
}

