# Genera la version con fecha/hora actual y lanza flutter build apk --release
# Para ejecutarlo:
# cd kobra_app
# .\build_release.ps1
$now = Get-Date
$version = '{0}.{1}.{2}.{3}' -f $now.ToString('HH'), $now.ToString('dd'), $now.ToString('MM'), $now.ToString('yy')

$versionFile = Join-Path $PSScriptRoot 'lib\version.dart'
Set-Content -Path $versionFile -Encoding utf8 -Value "const String appVersion = '$version';"

Write-Host "Version: $version"
flutter build apk --release @args
