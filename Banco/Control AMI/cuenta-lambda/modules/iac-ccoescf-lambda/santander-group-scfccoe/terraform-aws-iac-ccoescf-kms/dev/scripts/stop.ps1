using namespace System
using namespace System.IO
using namespace System.Linq
using namespace System.Management.Automation.Host

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Environment = $env:ENVIRONMENT
)

Write-Host 'Welcome to Terraform DEV Resources DESTROY pipeline.'
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
    $Environment = Read-Host "Please enter a valid environment value"
}

# RESOLVE environment from given (to avoid casing errors).
$Environment = [Enumerable]::SingleOrDefault([string[]]$AvailableEnvironments, $EnvironmentComparerDelegate)
$env:ENVIRONMENT = $Environment

[string]$script:VarFilePath = Join-Path -Path $EnvironmentRootPath -ChildPath "$Environment/terraform.tfvars"
Write-Host
Write-Host "Environment SET as '$Environment'" -ForegroundColor Green
Write-Host ".tfvars file RESOLVED to: '$VarFilePath'" -ForegroundColor Green

# INIT
terraform init -input=false

if (!$?) {        
    throw "Error on terraform init process."
}

# PLAN destroy
# Note: The -destroy option to terraform apply exists only in Terraform v0.15.2 and later. See: https://www.terraform.io/cli/commands/destroy#usage
[PSCustomObject]$script:terraformVersion = $(terraform version -json) | ConvertFrom-Json
if ([System.version]::Parse($terraformVersion.terraform_version) -ge [System.version]::Parse("0.15.2")) {    
    terraform plan -destroy -var-file="$VarFilePath"
}

Write-Host
Write-Host "Do you really want to destroy all resources?
    Terraform will destroy all your managed infrastructure, as shown above.
    There is no undo. Only 'yes' will be accepted to confirm."
$MustDestroy = Read-Host "Enter a value"

if ($MustDestroy -notlike "yes") {
    Write-Host "Destroy cancelled." -ForegroundColor Yellow
    Exit
}

# DESTROY
[bool]$StopLoop = $false
[int]$MaxRetries = 3
[int]$RetryCount = 0
 
do {
    try {
        [int]$Attempt = $RetryCount + 1
        Write-Host "Performing 'terraform destroy'. Attempt ${Attempt}/${MaxRetries}:"
        terraform destroy -var-file="$VarFilePath" -auto-approve

        if (!$?) {        
            throw "Error on terraform destroy process."
        }

        Write-Host "All resources have been successfully destroyed." -ForegroundColor Green
        $StopLoop = $true
    }
    catch {
        if ($RetryCount -gt $MaxRetries) {
            Write-Host "Could not perform destroy action after ${MaxRetries} retries." -ForegroundColor Red
            $StopLoop = $true
        }
        else {
            Write-Host "Could not destroy some resources. Retrying in 30 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            $RetryCount++
        }
    }
    finally {        
        Pop-Location
    }
}
While ($false -eq $StopLoop)