
function ConvertFrom-Html {
    <#
    .SYNOPSIS
        Takes an HTML input and converts it to an HTMLAgilityPack htmlNode object that can be navigated using Linq
    .DESCRIPTION
        Long description
    .EXAMPLE
        $HTMLString = @'
        <!DOCTYPE html>
        <html>
        <body>
        <h1>My First Heading</h1>
        <p>My first paragraph.</p>d
        </body>
        </html>
'@ | ConvertFrom-HTML

        $HTMLString

    NodeType Name      AttributeCount ChildNodeCount ContentLength InnerText
    -------- ----      -------------- -------------- ------------- ---------
    Document #document 0              4              103               …

        $HTMLString.SelectSingleNode('//body/h1')

    NodeType Name AttributeCount ChildNodeCount ContentLength InnerText
    -------- ---- -------------- -------------- ------------- ---------
    Element  h1   0              1              16            My First Heading

        Convert HTML string to a HtmlNode via the pipeline.

    .EXAMPLE
        $uri = [Uri]'https://www.powershellgallery.com/' | ConvertFrom-HTML
        $uri

    NodeType Name      AttributeCount ChildNodeCount ContentLength InnerText
    -------- ----      -------------- -------------- ------------- ---------
    Document #document 0              4              17550         …

        Fetch and parse a url.
    .EXAMPLE
        Get-Item $testFilePath | ConvertFrom-Html

    NodeType Name      AttributeCount ChildNodeCount ContentLength InnerText
    -------- ----      -------------- -------------- ------------- ---------
    Document #document 0              5              105               …

        Parse an HTML file piped from Get-Item.
    .INPUTS
        [String[]]
        [System.IO.FileInfo[]]
        [System.URI[]]
    .OUTPUTS
        [HtmlAgilityPack.HtmlDocument]
        [HtmlAgilityPack.HtmlNode]
    .NOTES
        General notes
    #>
    [OutputType([HtmlAgilityPack.HtmlNode])]
    [OutputType([HtmlAgilityPack.HtmlDocument])]
    [CmdletBinding(DefaultParameterSetName = 'String')]
    param(
        #The HTML text to parse. Accepts multiple separate documents as an array. This also accepts pipeline from Invoke-WebRequest
        [Parameter(ParameterSetName = 'String', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [String[]] $Content,

        #The URI or URIs from which to retrieve content. This may be faster than using Invoke-WebRequest but is less flexible in the method of retrieval (for instance, no POST)
        [Parameter(ParameterSetName = 'URI', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [System.URI[]] $URI,

        #Path to file or files containing HTML content to convert. This accepts pipeline from Get-Childitem or Get-Item
        [Parameter(ParameterSetName = 'Path', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [System.IO.FileInfo[]] $Path,

        #Do not return the Linq documentnode, instead return the HTMLDocument object. This is useful if you want to do XPath queries instead of Linq queries
        [switch] $Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'String' {
                $Content | ForEach-Object {
                    Write-Verbose "Loading HTML $_"
                    $html = [HtmlAgilityPack.HtmlDocument]::new()
                    $html.LoadHtml($_)
                    if ($Raw) { $html } else { $html.DocumentNode }
                }
            }
            'URI' {
                $URI | ForEach-Object {
                    Write-Verbose "Loading URI $_"
                    $web = [HtmlAgilityPack.HtmlWeb]::new()
                    $html = $web.Load($_)
                    if ($Raw) { $html } else { $html.DocumentNode }
                }
            }
            'Path' {
                $Path | ForEach-Object {
                    Write-Verbose "Loading File $_"
                    $html = [HtmlAgilityPack.HtmlDocument]::new()
                    $html.Load($_.FullName)
                    if ($Raw) { $html } else { $html.DocumentNode }
                }
            }
            default {
                Write-Error 'Input Object Type Not Identified. ConvertFrom-HTML needs better input validation'
                return
            }
        }
    }
}
