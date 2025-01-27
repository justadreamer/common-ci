
param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [string]$GitHubUser = "",
    [string]$GitHubEmail = "",
    [string]$DeviceDetectionKey,
    [string]$DeviceDetectionUrl,
    [string]$GitHubToken,
    [bool]$DryRun = $False
)

. ./constants.ps1

if ($GitHubUser -eq "") {
    $GitHubUser = $DefaultGitUser
}
if ($GitHubEmail -eq "") {
    $GitHubEmail = $DefaultGitEmail
}

# This token is used by the hub command.
Write-Output "Setting GITHUB_TOKEN"
$env:GITHUB_TOKEN="$GitHubToken"

Write-Output "::group::Configure Git"
./steps/configure-git.ps1 -GitHubToken $GitHubToken -GitHubUser $GitHubUser -GitHubEmail $GitHubEmail
Write-Output "::endgroup::"

Write-Output "::group::Clone $RepoName - $PropertiesUpdateBranch"
./steps/clone-repo.ps1 -RepoName $RepoName -OrgName $OrgName -Branch $PropertiesUpdateBranch
Write-Output "::endgroup::"

Write-Output "::group::Clone Tools"
./steps/clone-repo.ps1 -RepoName "tools" -OrgName $OrgName
Write-Output "::endgroup::"

Write-Output "::group::Options"
$Options = @{
    DeviceDetectionKey = $DeviceDetectionKey
    DeviceDetectionUrl = $DeviceDetectionUrl
    TargetRepo = $RepoName
}
Write-Output "::endgroup::"

Write-Output "::group::Fetch Assets"
./steps/run-repo-script.ps1 -RepoName "tools" -OrgName $OrgName -ScriptName "fetch-assets.ps1" -Options $Options -DryRun $DryRun
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Generate Accessors"
./steps/run-repo-script.ps1 -RepoName "tools" -OrgName $OrgName -ScriptName "generate-accessors.ps1" -Options $Options -DryRun $DryRun
Write-Output "::endgroup::"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "::group::Has Changed"
./steps/has-changed.ps1 -RepoName $RepoName
Write-Output "::endgroup::"

if ($LASTEXITCODE -eq 0) {
    
    Write-Output "::group::Commit Changes"
    ./steps/commit-changes.ps1 -RepoName $RepoName -Message "REF: Updated properties."
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    Write-Output "::group::Push Changes"
    ./steps/push-changes.ps1 -RepoName $RepoName -Branch $PropertiesUpdateBranch -DryRun $DryRun
    Write-Output "::endgroup::"

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    Write-Output "::group::PR To Main"
    ./steps/pull-request-to-main.ps1 -RepoName $RepoName -Message "Updated properties." -DryRun $DryRun
    Write-Output "::endgroup::"

}
else {

    Write-Host "No property changes, so not creating a pull request."

}

exit 0
