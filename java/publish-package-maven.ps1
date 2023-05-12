param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$MavenSettings,
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    # We need to set the version here again even though the packages are already built using the next version
    # as this script will run in a new job and the repo will be cloned again.
    Write-Output "Setting version to '$Version'"
    mvn versions:set -DnewVersion="$Version"

    $settingsFile = "stagingsettings.xml"

    Write-Output "Writing Settings File"
    $SettingsContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($MavenSettings))
    Set-Content -Path $SettingsFile -Value $SettingsContent
    $SettingsPath = [IO.Path]::Combine($RepoPath, $SettingsFile)
    

    Write-Output "Deploying to Nexus staging"
    
    mvn nexus-staging:deploy-staged `
        -s $SettingsPath  `
        -f pom.xml `
        -DXmx2048m `
        -DskipTests `
        --no-transfer-progress `
        "-Dhttps.protocols=TLSv1.2" `
        "-DfailIfNoTests=false" 

    if ($($Version.EndsWith("SNAPSHOT")) -eq $False) {

        Write-Output "Releasing from Nexus to Maven central"
        #mvn nexus-staging:release
    
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}
