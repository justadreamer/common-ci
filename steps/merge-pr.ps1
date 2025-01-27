param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$OrgName,
    [Parameter(Mandatory=$true)]
    [int]$PullRequestId,
    [bool]$DryRun = $False
)

. ./constants.ps1

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    if ($PullRequestId -eq 0) {

        Write-Output "Not running for a PR"
        exit 0
    
    }
    
    # For the format argument, see https://hub.github.com/hub-pr.1.html
    $PrTitle = $(hub pr show $PullRequestId -f "%i %H->%B : '%t'")

    Write-Output "Merging PR $PrTitle"
    $Command = "hub api /repos/$OrgName/$RepoName/pulls/$PullRequestId/merge -X PUT -f `"commit_title=Merged Pull Request '$PrTitle'`""
    if ($DryRun -eq $False) {
        Invoke-Expression $Command
    }
    else {
        Write-Output "Dry run - not executing the following: $Command"
    }
    
}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
