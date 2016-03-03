$root = $psscriptroot
if ([string]::isnullorempty($root)) {
    $root = "."
}

write-host "64bit=$([Environment]::Is64BitProcess)"

#if ($host.name -eq "Windows PowerShell ISE Host" -and (gmo pester)) { rmo pester }
import-module pester
$i = (gi "$root\..\src")
$fp = (gi "$root\..\src").fullname
write-verbose "adding path of $i '$fp' to psmodulepath"
$env:PSModulePath ="$fp;$env:PSModulePath"

if ((pwd).Drive.Name -eq "TestDrive") {
    cd c:\
}

if ($host.name -eq "Windows PowerShell ISE Host" -or $host.name -eq "ConsoleHost") {
    write-Verbose "reloading csproj"
    if (gmo csproj) {
        rmo csproj 
    }
    write-Verbose "importing csproj"
    import-module csproj -DisableNameChecking
    write-Verbose "reloading csproj DONE"
}

import-module logging -DisableNameChecking

if ((get-module logging) -eq  $null) {
    write-host "importing logging"
    import-module logging -DisableNameChecking    
    if ((get-module logging) -ne $null) {
        $Global:logpattern.Add("""(?<magenta>.*?)""", "quoted names")
        $Global:logpattern.Add("<(?<cyan>[a-zA-Z]+)", "xml node start")
        $Global:logpattern.Add("/(?<cyan>[a-zA-Z]+)>", "xml node end")
    }
    else {
        function log-info($message = "") {
            write-host -ForegroundColor Cyan $message
        }
    }
}

$inputdir = "$psscriptroot\input"

function get-testoutputdir() {
    $targetdir = "testdrive:"
    if (get-command get-pesterstate -ErrorAction Ignore -and $false) {
        $s = get-pesterstate
        $targetdir = "$psscriptroot\test-results\$(get-date -Format "yyyy-MM-dd HHmmss")-$($s.currentdescribe)"
    }
    if (!(test-path $targetdir)) { $null = new-item -ItemType directory $targetdir }
    return $targetdir
}

write-host "== includes END =="