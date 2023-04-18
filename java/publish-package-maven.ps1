param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Version
)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Setting package version"
    mvn versions:set -DnewVersion="$Version"

    Write-Output "Deploying to Nexus staging"
    mvn deploy

    if ($($Version.EndsWith("SNAPSHOT")) -eq $False) {

        Write-Output "Releasing from Nexus to Maven central"
        mvn nexus-staging:release
    
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
