#!/usr/bin/env powershell

# Direct Flutter build script bypassing batch file issues
$flutterRoot = "c:\Users\kevin\Documents\DinoManager\flutter"
$dartSdk = "$flutterRoot\bin\cache\dart-sdk"
$dart = "$dartSdk\bin\dart.exe"
$flutterToolsDir = "$flutterRoot\packages\flutter_tools"
$snapshot = "$flutterRoot\bin\cache\flutter_tools.snapshot"
$workDir = "c:\Users\kevin\Documents\DinoManager\flutter_app"

Write-Host "Flutter Build Script"
Write-Host "===================="
Write-Host "Flutter Root: $flutterRoot"
Write-Host "Dart: $dart"
Write-Host "Work Dir: $workDir"
Write-Host ""

cd $workDir

Write-Host "Step 1: Cleaning build..."
& $dart --packages="$flutterToolsDir\.dart_tool\package_config.json" "$snapshot" clean

Write-Host "Step 2: Getting dependencies..."
& $dart --packages="$flutterToolsDir\.dart_tool\package_config.json" "$snapshot" pub get

Write-Host "Step 3: Building app bundle..."
& $dart --packages="$flutterToolsDir\.dart_tool\package_config.json" "$snapshot" build appbundle

Write-Host "Build complete!"
