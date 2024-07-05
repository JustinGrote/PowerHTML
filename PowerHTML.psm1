#Get public and private function definition files.
$PublicFunctions = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction Ignore )

#Dot source the files
foreach ($FunctionToImport in $PublicFunctions) {
    try {
        . $FunctionToImport.fullname
    } catch {
        Write-Error -Message "Failed to import function $($FunctionToImport.fullname)"
    }
}
