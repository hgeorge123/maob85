[string]$script:RootPath = $PSScriptRoot

$availableEnvironments = Get-ChildItem "${RootPath}/../environment" -Directory | Select-Object -ExpandProperty Name
foreach ($environment in $availableEnvironments) {
    Write-Host
    Write-Host
    Write-host "Press [Escape] key to avoid testing ENVIRONMENT: '$environment'" -ForegroundColor Magenta
    Write-Host "Press any other key to continue..." -ForegroundColor Magenta
    [System.ConsoleKeyInfo] $script:key = [console]::ReadKey()
    if ($key.Key -eq [System.ConsoleKey]::Escape) {
        Write-Host
        Write-Host "Environment: '$environment' SKIPPED." -ForegroundColor DarkYellow
        continue
    }
    . "$RootPath/start.ps1" -Environment $environment
}