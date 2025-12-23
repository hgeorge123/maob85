using namespace System
using namespace System.IO
using namespace System.Linq
using namespace System.Management.Automation.Host

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Environment = $env:ENVIRONMENT,
    [Parameter()]
    [String]
    $TargetModuleName = $env:TF_TARGET,
    [Parameter()]
    [String]
    $PreTerraformInitCommand = $env:TF_PREINITCOMMAND,
    [Parameter()]
    [String]
    $PostTerraformInitCommand = $env:TF_POSTINITCOMMAND
)

Write-Host 'Welcome to Terraform DEV pipeline.'
Write-Host

[string]$script:RootPath = $PSScriptRoot

[string]$script:TerraformConfigurationPath = Join-Path "$RootPath" -ChildPath "../" -Resolve
Write-Host "Terraform workspace path: '$TerraformConfigurationPath'" -ForegroundColor Green

Push-Location $TerraformConfigurationPath

Write-Host 
Write-Host 'CHECKING defined environments...'
[string]$script:EnvironmentRootPath = Join-Path -Path "$RootPath" -ChildPath "/../environment" -Resolve

if (!$?) {
    throw "'dev/environment' directory could not be found."
}

# GET Available environments (folders) from 'dev/environment' directory
[string[]]$script:AvailableEnvironments = Get-ChildItem $EnvironmentRootPath -Directory | Select-Object -ExpandProperty Name

if (!$? -or ($AvailableEnvironments.Length -eq 0)) {
    throw "No environments could be retrieved from 'dev/environment' directory."
}

Write-Host "FOUND Environments:"
$AvailableEnvironments

# CHECK whether given environment is one of available
[Func[string, bool]]$script:EnvironmentComparerDelegate = [Func[string, bool]] {
    [StringComparer]::OrdinalIgnoreCase.Equals($args[0], $Environment) 
}

while (![Enumerable]::Any([string[]]$AvailableEnvironments, $EnvironmentComparerDelegate)) {
    Write-Host
    Write-Host "Current Environment value is: '${Environment}'" -ForegroundColor Yellow
    Write-Host "Environment parameter must be one of those values: "
    $AvailableEnvironments

    Write-Host
    $Environment = $(Write-Host "Please enter a valid environment value: " -ForegroundColor Magenta -NoNewline; Read-Host)
}

# RESOLVE environment from given (to avoid casing errors).
$Environment = [Enumerable]::SingleOrDefault([string[]]$AvailableEnvironments, $EnvironmentComparerDelegate)
$env:ENVIRONMENT = $Environment

[string]$script:VarFilePath = Join-Path -Path $EnvironmentRootPath -ChildPath "$Environment/terraform.tfvars"
Write-Host
Write-Host "Environment SET as '$Environment'" -ForegroundColor Green
Write-Host ".tfvars file RESOLVED to: '$VarFilePath'" -ForegroundColor Green

Write-Host
Write-Host "CREATING 'dev/out' directory (if not exists) to place .tfplan file..."
[string]$script:TFPlanRootPath = Join-Path -Path "$RootPath" -ChildPath "/../out"
New-Item -ItemType "directory" -Path "$TFPlanRootPath" -Force > $null

if (!($? -and (Test-Path $TFPlanRootPath))) {
    throw "'dev/out' directory to place .tfplan file does not exist and could not be created."
}

$TFPlanRootPath = ($TFPlanRootPath | Resolve-Path).Path
Write-Host "'$TFPlanRootPath' directory is AVAILABLE." -ForegroundColor Green

Set-Variable TfplanFilePath -Option ReadOnly -Value $(Join-Path -Path "$TFPlanRootPath" -ChildPath "plan.tfplan") -Scope "Script"
Write-Host
Write-Host "Terraform plan file: '$TfplanFilePath'" -ForegroundColor Green
Write-Host
Write-Host "PERFORMING terraform commands..."

try {
    # INIT
    if (![string]::IsNullOrWhiteSpace($PreTerraformInitCommand)) {
        Write-Host
        Write-Host "INVOKING PreTerraformInitCommand..."
        Invoke-Expression $PreTerraformInitCommand
        Write-Host "PreTerraformInitCommand INVOKED."
    }

    Write-Host
    Write-Host "INITIALIZING terraform..."
    terraform init -upgrade -input=false
    
    if (!$?) {
        Invoke-Expression $SetProxyCommand
        throw "Error on terraform init process."
    }

    if (![string]::IsNullOrWhiteSpace($PostTerraformInitCommand)) {
        Write-Host
        Write-Host "INVOKING PostTerraformInitCommand..."
        Invoke-Expression $PostTerraformInitCommand
        Write-Host "PostTerraformInitCommand INVOKED."
    }

    # VALIDATE
    Write-Host
    Write-Host "VALIDATING terraform config..."
    terraform validate

    if (!$?) {        
        throw "Error on terraform validation process."
    }

    # GLOBAL PLAN
    Write-Host
    Write-Host "EVALUATING terraform changes..."
    terraform plan -input=false -var-file="$VarFilePath" -out="$TfplanFilePath" > $null

    if (!$?) {
        throw "Error on terraform plan process."
    }

    # SELECT MODULES TO APPLY
    Write-Host
    Write-Host "DETECTING modules to be changed..."
    [PSCustomObject]$script:Plan = terraform show -json "$TfplanFilePath" | ConvertFrom-Json
    [string[]]$script:PlanModules = $Plan.configuration.root_module.module_calls | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    Write-Host 
    Write-Host "Detected modules to be tested:"
    [int]$script:PlanModuleIndex = 1
    foreach ($moduleName in $PlanModules) {
        Write-Host "[$PlanModuleIndex] $moduleName"
        $PlanModuleIndex++
    }
    
    Write-Host
    [ushort]$script:SelectedModuleIndex = $(Write-Host "Enter the module index with changes to be performed. (Empty to perform all changes): " -ForegroundColor Magenta -NoNewline; Read-Host)
        
    if ($SelectedModuleIndex -gt 0) {
        Write-Host
        Write-Host "Selected Index: $SelectedModuleIndex"
        [string]$script:TargetModuleName = "module.$($PlanModules[$SelectedModuleIndex - 1])"
        Write-Host "Target Module: $TargetModuleName" -ForegroundColor Green
    
        # TARGET PLAN
        Write-Host
        Write-Host "PLAN changes targeting '$TargetModuleName'"
        terraform plan -target="$TargetModuleName" -input=false -var-file="$VarFilePath" -out="$TfplanFilePath"
    }
    else {
        Write-Host
        Write-Host "NO module has been selected as target. All changes shall be performed." -ForegroundColor Yellow
        terraform show "$TfplanFilePath"
    }

    # APPLY
    Write-Host "Do you want to perform these actions?
        Terraform will perform the actions described above.
        Only 'yes' will be accepted to approve."
    $script:CanApply = Read-Host "Enter a value"

    if ($CanApply -notlike "yes") {        
        Write-Host "Apply cancelled." -ForegroundColor Yellow
        Exit
    }

    terraform apply -input=false -auto-approve "${TfplanFilePath}"

    if (!$?) {        
        throw "Error on terraform apply process."
    }
}
catch {
    Write-Error $_.Exception.Message
}
finally {
    if (Test-Path $TfplanFilePath) {
        Remove-Item -Path $TfplanFilePath -Force
    }
    
    Remove-Variable TfplanFilePath -Force
    Pop-Location
}