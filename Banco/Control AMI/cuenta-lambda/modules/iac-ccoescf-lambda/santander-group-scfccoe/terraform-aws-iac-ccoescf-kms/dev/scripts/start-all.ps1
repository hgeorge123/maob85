[string]$script:RootPath = $PSScriptRoot

$availableEnvironments = Get-ChildItem "${RootPath}/../environment" -Directory | Select-Object -ExpandProperty Name
foreach ($environment in $availableEnvironments) {
    Write-Host
    Write-Host
    Write-host "Press [Escape] key to avoid testing ENVIRONMENT: '$environment'" -ForegroundColor DarkCyan
    Write-Host "Press any other key to continue..." -ForegroundColor DarkCyan
    [System.ConsoleKeyInfo] $script:key = [console]::ReadKey()
    
    if ($key.Key -eq [System.ConsoleKey]::Escape) {
        Write-Host
        Write-Host "Environment: '$environment' SKIPPED." -ForegroundColor DarkYellow
        continue
    }

    . "$RootPath/start.ps1" -Environment $environment
    
    Write-host "Press [Escape] key to avoid running 'terraform destroy' in ENVIRONMENT: '$environment'" -ForegroundColor Magenta
    Write-Host "Press any other key to continue..." -ForegroundColor Magenta
    [System.ConsoleKeyInfo] $script:key = [console]::ReadKey()
    
    if($key.Key -eq [System.ConsoleKey]::Escape) {
        Write-Host
        Write-Host "Destroy Environment action: '$environment' SKIPPED." -ForegroundColor DarkYellow
        continue
    }

    . "$RootPath/stop.ps1" -Environment $environment
}