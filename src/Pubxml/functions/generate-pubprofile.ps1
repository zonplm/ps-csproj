function generate-pubprofile {
param(
    [parameter(mandatory = $true)]$machine,
    $projectroot = ".", 
    [string]$profilename = "publish-default", 
    [switch][bool]$reset,
    $appPath = $null,
    $username = $null,
    $customParams = @{}
)
    $projectroot = (gi $projectroot).FullName
    $profilename = $profilename -replace "\.pubxml$",""

    $profilePath = join-path $projectRoot "properties/PublishProfiles/$profilename.pubxml"
    if ($appPath -eq $null) {
        $appPath = split-path $projectroot -Leaf
    }

    $isVnext = (gci $projectroot -Filter "*.xproj").Length -gt 0



    $defaultprofle = @{ 
        vnext = "$psscriptroot\empty-vnext.pubxml"
        vnextscript = "$psscriptroot\empty-vnext-publish.ps1"
        old = "$psscriptroot\empty.pubxml"
    }


    if ($reset) {
        if (test-path $profilePath) { remove-item $profilePath }
        $basename = [System.IO.Path]::GetFileNameWithoutExtension($profilePath)
        $profileDir = Split-Path -Parent $profilePath
        $pubscriptPath = (join-path $profileDir "$basename-publish.ps1")   
        if (test-path $pubscriptPath) { remove-item $pubscriptPath }
    }
    if (!(test-path $profilePath)) {
        write-host "profile $profilepath not found. creating..."
        $profileDir = Split-Path -Parent $profilePath
        if (!(test-path $profileDir)) { new-item $profileDir -type directory }
        if ($isVnext) {
            Copy-Item $defaultprofle.Vnext $profilePath
            $basename = [System.IO.Path]::GetFileNameWithoutExtension($profilePath)
                    
            Copy-Item $defaultprofle.vnextscript (join-path $profileDir "$basename-publish.ps1")                    
        }
        else {
            Copy-Item $defaultprofle.old $profilePath
        }
    }     
    if ([string]::IsNullOrEmpty($machine)) {
        throw "Machine property is not set!"
    }      
    if ($machine -ne $null) {                
        $machine = $machine 
        if (!$isVnext) { $machine = "https://$machine/msdeploy.axd" }
                
    }

          
    $addtionalProps = @{ }   
    $addtionalProps["subdir"] = ""    
    $addtionalProps["Recycle"] = "True"
    $customParams.GetEnumerator() | % {    
        $key = $_.key
        $value =$_.value
        if ($key -ieq "subdir") {
            $addtionalProps["subdir"] = $value
            $addtionalProps["Recycle"] = "False"
        }
        elseif ($key -ieq "SkipServerFiles") {            
            $addtionalProps["SkipExtraFilesOnServer"] = "$value"
        }
        else {
            #should we add this?
            $addtionalProps[$key] = "$value"
        }
    }
           
    if ($isVnext -and $appPath -ne $null -and $appPath -notmatch "-deploy") {
        
        $appPath = $appPath + "-deploy"
    }

    update-pubprofile $profilePath -serverUrl $machine -appPath $appPath -username $username  -Verbose -properties $addtionalProps
}