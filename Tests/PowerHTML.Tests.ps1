#Move out of tests to the subdirectory of the modulepwd
if ((get-item .).Name -match 'Tests') {Set-Location $PSScriptRoot\..}

$ModuleName = 'PowerHTML'
$ModuleManifestName = "$ModuleName.psd1"
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
Describe 'Module Integrity' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath | Should Not BeNullOrEmpty
        $? | Should Be $true
    }
    It 'Can Be Imported as a module' {
        (Import-Module -Force -Name $PSScriptRoot\.. -PassThru).Name | Should Be $ModuleName
    }
}

Describe 'HTML Basic Conversion' {
    $HTMLString = @"
    <!DOCTYPE html>
<html>
<body>
<h1>My First Heading</h1>
<p>My first paragraph.</p>d
</body>
</html>
"@

    $HTMLString2 = @"
<!DOCTYPE html>
<html>
<body>
<h1>My First Heading</h1>
<p>My first paragraph.</p>
</body>
</html>
"@

    #Generate test files to a random path
    $guid = [GUID]::NewGuid().guid
    $testFilePath1 = "$env:temp/pester-$guid.htmltest"
    $testFilePath2 = "$env:temp/pester-$guid`2.htmltest"
    $testFilePathAll = "$env:temp/pester-$guid`*"
    $HTMLString > $testFilePath1
    $HTMLString > $testFilePath2

    It 'Can convert an HTML string to a raw HTMLDocument via the pipeline' {
        $HTMLString | ConvertFrom-HTML -Raw | Should Be HtmlAgilityPack.HTMLDocument
    }
    It 'Can parse an HTML string to a HtmlNode via the pipeline' {
        $HTMLString | ConvertFrom-HTML | Should Be HtmlAgilityPack.HTMLNode
    }
    It 'Can parse multiple HTML strings to HtmlNodes when passed via the pipeline as an array' {
        $result = $HTMLString,$HTMLString2 | ConvertFrom-HTML
        $result.count | Should Be 2
        foreach ($resultItem in $result) {
            $resultItem | Should Be HtmlAgilityPack.HTMLNode
        }
    }
    It 'Can parse an HTML file' {
        ConvertFrom-Html -Path $testFilePath1 | Should Be HtmlAgilityPack.HTMLNode
    }
    It 'Can parse multiple HTML files' {
        $result = ConvertFrom-Html -Path $testFilePath1,$testFilePath2
        $result.count | Should Be 2
        foreach ($resultItem in $result) {
            $resultItem | Should Be HtmlAgilityPack.HTMLNode
        }
    }
    It 'Can parse an HTML file piped from Get-Item' {
        Get-Item $testFilePath1 | ConvertFrom-Html | Should Be HtmlAgilityPack.HTMLNode
    }
    It 'Can parse multiple HTML files piped from Get-Item' {
        $result = Get-Item $testFilePathAll | ConvertFrom-Html
        $result.count | Should Be 2
        foreach ($resultItem in $result) {
            $resultItem | Should Be HtmlAgilityPack.HTMLNode
        }
    }

    #Cleanup
    Remove-Item $testFilePath1,$testFilePath2 -Erroraction silentlycontinue -force
}

Describe 'HTTP Operational Tests - REQUIRES INTERNET CONNECTION!' {
    $uri = "https://www.google.com"
    $uriObjects = [uri]$uri,[uri]"https://www.facebook.com",[uri]"https://www.twitter.com"
    It "Can fetch and parse $uri directly via the URI pipeline" {
        $result = ConvertFrom-HTML -uri $uri
        $result | Should Be HtmlAgilityPack.HTMLNode
        $result.innertext -match 'Google' | Should Be $true
    }
    It "Can parse $uri piped from Invoke-WebRequest" {
        $result = Invoke-WebRequest $uri | ConvertFrom-HTML
        $result | Should Be HtmlAgilityPack.HTMLNode
        $result.innertext -match 'Google' | Should Be $true
    }
    It "Can parse multiple URI objects passed via the pipeline (Google,Facebook,Twiiter)" {
        $result = $uriObjects | ConvertFrom-HTML
        foreach ($resultItem in $result) {
            $resultItem | Should Be HtmlAgilityPack.HTMLNode
        }
        $result[0].innertext -match 'Google' | Should Be $true
        $result[1].innertext -match 'Facebook' | Should Be $true
        $result[2].innertext -match 'Twitter' | Should Be $true
    }
}