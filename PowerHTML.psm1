#Get public and private function definition files.
$PublicFunctions  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Get JSON settings files
$ModuleSettings = @( Get-ChildItem -Path $PSScriptRoot\Settings\*.json -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($FunctionToImport in @($PublicFunctions + $PrivateFunctions))
{
    Try
    {
        . $FunctionToImport.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

#Import Settings files as global objects based on their filename
foreach ($ModuleSettingsItem in $ModuleSettings)
{
    New-Variable -Name "$($ModuleSettingsItem.basename)" -Scope Global -Value (convertfrom-json (Get-Content -raw $ModuleSettingsItem.fullname)) -Force
}

#Export the public functions. This requires them to match the standard Noun-Verb powershell cmdlet format as a safety mechanism
Export-ModuleMember -Function ($PublicFunctions.Basename | where {$PSitem -match '^\w+-\w+$'})