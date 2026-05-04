param(
    [string]$Message = "update"
)

$ErrorActionPreference = "Stop"

git status --short
git add -A

$pending = git status --short
if (-not $pending) {
    Write-Host "No changes to sync."
    exit 0
}

git commit -m $Message
git push
