$logLocation = "%userprofile%\AppData\LocalLow\miHoYo\Genshin Impact\output_log.txt";
$logLocationChina = "%userprofile%\AppData\LocalLow\miHoYo\$([char]0x539f)$([char]0x795e)\output_log.txt";

# https://stackoverflow.com/a/29434931
$isUserAdmin = $null -ne (whoami /groups /fo csv | ConvertFrom-Csv | Where-Object { $_.SID -eq "S-1-5-32-544" })

# Check if Path to output_log do exists
function doPathExists($p){
    try {
        $test = Test-Path -Path $p -ErrorAction Stop
        return $test
    }
    catch {
        Write-Debug $_
        return $false
    }
}

$path = [System.Environment]::ExpandEnvironmentVariables($logLocation);
if ((doPathExists($path)) -ne $true) {
    $path = [System.Environment]::ExpandEnvironmentVariables($logLocationChina);
    if ((doPathExists($path)) -ne $true) {
        Write-Host "Genshin folder not found in current User Profile folder." -ForegroundColor Red

        # If Path does not exists, then, check if the current user is Admin
        if (-not $isUserAdmin) {
            # If not, inform user and ask for permission to run as Admin
            Write-Host ("`nThis script also detected that the current user is not an Administrator," +
                        "`nsince Genshin Impact is required to run as Administrator," +
                        "`nit is possible that this script will also need Admin Rights to" +
                        "`nread the files.") -ForegroundColor Red

            Write-Host ("`nThis script will now run with Admin Rights," +
                        "`nif you want to continue, press any key," +
                        "`nif you want to Abort, press ESC.") -ForegroundColor Red
            $keyCode = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            if ($keyCode.VirtualKeyCode -eq 27) {
                # If the user dont want to run as Admin, he can press ESC(27) to abort
                return
            } else {
                # To run as admin, the script need to start another Powershell terminal
                # running it as Admin and run the same script again.
                # https://stackoverflow.com/a/60216595
                $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
                $newProcess.Arguments = "-NoExit " + $myInvocation.MyCommand.Definition;
                $newProcess.Verb = "runas";

                [System.Diagnostics.Process]::Start($newProcess);
                exit
            }
            return
        }
        Write-Host "Make sure to run the game and open the wish history first." -ForegroundColor Red
    }
}

if (-Not [System.IO.File]::Exists($path)) {
    Write-Host "We cannot find the log file! Make sure to open the wish history ingame first!" -ForegroundColor Red
    return
}

$logs = Get-Content -Path $path
$match = $logs -match "^OnGetWebViewPageFinish.*log$"
if (-Not $match) {
    Write-Host "We cannot find the wish history url! Make sure to open the wish history ingame first!" -ForegroundColor Red
    return
}

[string] $wishHistoryUrl = $match[$match.count-1] -replace 'OnGetWebViewPageFinish:', ''
Write-Host $wishHistoryUrl
Set-Clipboard -Value $wishHistoryUrl
Write-Host "Link copied to clipboard, paste it on Genshin Wishes" -ForegroundColor Green
