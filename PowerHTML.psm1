#Get public and private function definition files.
$PublicFunctions = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction Ignore )
$PrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction Ignore )

#Get JSON settings files
$ModuleSettings = @( Get-ChildItem -Path $PSScriptRoot\Settings\*.json -ErrorAction Ignore )

#Determine which assembly versions to load
#See if .Net Standard 2.0 is available on the system and if not, load the legacy Net 4.0 library
try {
    Add-Type -AssemblyName 'netstandard, Version=2.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' -ErrorAction Stop
    #If netstandard is not available it won't get this far
    $dotNetTarget = "netstandard2"
} catch {
    $dotNetTarget = "net40-client"
}

$AssembliesToLoad = Get-ChildItem -Path "$PSScriptRoot\lib\*-$dotNetTarget.dll"
if ($AssembliesToLoad) {
    #If we are in a build or a pester test, load assemblies from a temporary file so they don't lock the original file
    #This helps to prevent cleaning problems due to a powershell session locking the file because unloading a module doesn't unload assemblies
    if ($BuildTask -or $TestDrive) {
        write-verbose "Detected Invoke-Build or Pester, loading assemblies from a temp location to avoid locking issues"
        if ($Global:BuildAssembliesLoadedPreviously) {
            write-warning "You are in a build or test environment. We detected that module assemblies were loaded in this same session on a previous build or test. Strongly recommend you kill the process and start a new session for a clean build/test!"
        }

        $TempAssembliesToLoad = @()
        foreach ($AssemblyPathItem in $AssembliesToLoad) {
            $TempAssemblyPath = [System.IO.Path]::GetTempFileName() + ".dll"
            Copy-Item $AssemblyPathItem $TempAssemblyPath
            $TempAssembliesToLoad += [System.IO.FileInfo]$TempAssemblyPath
        }
        $AssembliesToLoad = $TempAssembliesToLoad
        $Global:BuildAssembliesLoadedPreviously = $true
    }

    write-verbose "Loading Assemblies for .NET target: $dotNetTarget"
    Add-Type -Path $AssembliesToLoad.fullname -ErrorAction Stop
}

#Dot source the files
foreach ($FunctionToImport in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $FunctionToImport.fullname
    } catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

#Import Settings files as global objects based on their filename
foreach ($ModuleSettingsItem in $ModuleSettings) {
    New-Variable -Name "$($ModuleSettingsItem.basename)" -Scope Global -Value (convertfrom-json (Get-Content -raw $ModuleSettingsItem.fullname)) -Force
}

#Export the public functions. This requires them to match the standard Noun-Verb powershell cmdlet format as a safety mechanism
# Export-ModuleMember -Function ($PublicFunctions.Basename | Where-Object { $PSitem -match '^\w+-\w+$' })
Export-ModuleMember -Function *-*
