#Move out of tests to the subdirectory of the modulepwd
if ((get-item .).Name -match 'Tests') { Set-Location $PSScriptRoot\.. }

Describe 'HTML Basic Conversion' {
    BeforeAll {
        if (-not (Get-Module PowerHTML)) {
            Import-Module $PSScriptRoot\..\PowerHTML.psd1 -Force
        }
        $HTMLString = @'
<!DOCTYPE html>
<html>
<body>
<h1>My First Heading</h1>
<p>My first paragraph.</p>
</body>
</html>
'@
        $HTMLString2 = @'
<!DOCTYPE html>
<html>
<body>
<h1>Heading 1</h1>
<p>Paragraph 1.</p>
</body>
</html>
'@
        #Generate test files to a random path
        $testFilePath1 = New-TemporaryFile
        $testFilePath2 = New-TemporaryFile
        $testFilePathAll = @($testFilePath1,$testFilePath2)
        Add-Content -Path $testFilePath1 -Value $HTMLString
        Add-Content -Path $testFilePath2 -Value $HTMLString2
    }
    It 'Can convert an HTML string to a raw HTMLDocument via the pipeline' {
        $HTMLString | ConvertFrom-Html -Raw | Should -BeOfType HtmlAgilityPack.HTMLDocument
    }
    It 'Can parse an HTML string to a HtmlNode via the pipeline' {
        $HTMLString | ConvertFrom-Html | Should -BeOfType HtmlAgilityPack.HTMLNode
    }
    It 'Can parse multiple HTML strings to HtmlNodes when passed via the pipeline as an array' {
        $result = $HTMLString,$HTMLString2 | ConvertFrom-HTML
        $result.count | Should -Be 2
        foreach ($resultItem in $result) {
            $resultItem | Should -BeOfType HtmlAgilityPack.HTMLNode
        }
    }
    It 'Can parse an HTML file' {
        ConvertFrom-Html -Path $testFilePath1 | Should -BeOfType HtmlAgilityPack.HTMLNode
    }
    It 'Can parse multiple HTML files' {
        $result = ConvertFrom-Html -Path $testFilePath1,$testFilePath2
        $result.count | Should -Be 2
        foreach ($resultItem in $result) {
            $resultItem | Should -BeOfType HtmlAgilityPack.HTMLNode
        }
    }
    It 'Can parse an HTML file piped from Get-Item' {
        Get-Item $testFilePath1 | ConvertFrom-Html | Should -BeOfType HtmlAgilityPack.HTMLNode
    }
    It 'Can parse multiple HTML files piped from Get-Item' {
        $result = Get-Item $testFilePathAll | ConvertFrom-Html
        $result.count | Should -Be 2
        foreach ($resultItem in $result) {
            $resultItem | Should -BeOfType HtmlAgilityPack.HTMLNode
        }
    }
    AfterAll {
        Remove-Item $testFilePath1,$testFilePath2 -ErrorAction silentlycontinue -force
    }

}

Describe 'HTTP Operational Tests - REQUIRES INTERNET CONNECTION!' {
    BeforeAll {
        $uri = 'https://www.google.com'
        $uriObjects = [uri]$uri,[uri]'https://www.facebook.com',[uri]'https://www.twitter.com'
    }
    It 'Can fetch and parse $uri directly via the URI pipeline' {
        $result = ConvertFrom-HTML -uri $uri
        $result | Should -BeOfType HtmlAgilityPack.HTMLNode
        $result.innertext -match 'Google' | Should -Be $true
    }
    It 'Can parse $uri piped from Invoke-WebRequest' {
        $result = Invoke-WebRequest -verbose:$false $uri | ConvertFrom-HTML
        $result | Should -BeOfType HtmlAgilityPack.HTMLNode
        $result.innertext -match 'Google' | Should -Be $true
    }
    It 'Can parse multiple URI objects passed via the pipeline (Google,Facebook,Twiiter)' {
        $result = $uriObjects | ConvertFrom-HTML
        foreach ($resultItem in $result) {
            $resultItem | Should -BeOfType HtmlAgilityPack.HTMLNode
        }
        $result[0].innertext -match 'Google' | Should -Be $true
        $result[1].innertext -match 'Facebook' | Should -Be $true
        $result[2].innertext -match 'Twitter' | Should -Be $true
    }
}
