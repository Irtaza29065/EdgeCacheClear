# Date: Aug 22, 2023
# This script clears the bloated Microsoft Edge Cache file on Shared Private Desktop PCs

# Get a list of local user profiles
$localUsers = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false }

# Specify the path for the log files in the same directory as the script
$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "UserProfileSizes.log"
$errorLogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLog.log"

# Iterate through each user profile and calculate occupied space
foreach ($user in $localUsers) {
    try {
        $profilePath = $user.LocalPath
        $userSize = (Get-ChildItem -Path $profilePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB

        $edgeCachePath = Join-Path -Path $profilePath -ChildPath "AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage"
        $teamsCachePath = Join-Path -Path $profilePath -ChildPath "AppData\Roaming\Microsoft\Teams"

        if ((Test-Path $edgeCachePath) -or (Test-Path $teamsCachePath)) {
            $edgeCacheSize = (Get-ChildItem -Path $edgeCachePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
            $edgeOutput = "Edge Cache Size: $edgeCacheSize GB"
            
            # Clear Edge cache by deleting the cache directory
            Remove-Item -Path $edgeCachePath -Force -Recurse
            Remove-Item -Path $teamsCachePath -Force -Recurse
            $edgeOutput += " | Teams + Edge Cache Cleared for User"
        } else {
            $edgeOutput = "Operation Aborted: Microsoft Edge cache and/or Teams' Cache directory not found for this user"
        }
        
        $output = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - User: $($user.LocalPath.Split('\')[-1]) | Profile Size: $userSize GB | $edgeOutput"
        
        Write-Host $output
        $output | Out-File -Append -FilePath $logFilePath
    } catch {
        $errorMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error occurred for user: $($user.LocalPath.Split('\')[-1])"
        Write-Host $errorMessage
        $errorMessage | Out-File -Append -FilePath $errorLogFilePath
    }
}
