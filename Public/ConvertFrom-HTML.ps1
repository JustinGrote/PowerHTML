<#
.SYNOPSIS
    Takes an HTML input and converts it to an HTMLAgilityPack htmlNode object that can be navigated using Linq
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> $HTMLString = @"
    <!DOCTYPE html>
    <html>
    <body>
    <h1>My First Heading</h1>
    <p>My first paragraph.</p>d
    </body>
    </html>
    "@
 PS C:\> $HTMLString | ConvertFrom-HTML -OutVariable result

NodeType Name      AttributeCount ChildNodeCount ContentLength InnerText
-------- ----      -------------- -------------- ------------- ---------
Document #document 0              4              103               …

 PS C:\> $result.SelectSingleNode("//body/h1")

NodeType Name AttributeCount ChildNodeCount ContentLength InnerText
-------- ---- -------------- -------------- ------------- ---------
Element  h1   0              1              16            My First Heading

    Convert HTML string to a HtmlNode via the pipeline.

.EXAMPLE
    PS C:\> $uri = "https://www.powershellgallery.com/"
    PS C:\> $result = ConvertFrom-HTML -uri $uri
    PS C:\> $result

NodeType Name      AttributeCount ChildNodeCount ContentLength InnerText
-------- ----      -------------- -------------- ------------- ---------
Document #document 0              4              17550         …

    Fetch and parse $uri directly via the URI pipeline.
.EXAMPLE
    PS C:\>  Get-Item $testFilePath | ConvertFrom-Html

NodeType Name      AttributeCount ChildNodeCount ContentLength InnerText
-------- ----      -------------- -------------- ------------- ---------
Document #document 0              5              105               …

    Parse an HTML file piped from Get-Item.
.INPUTS
    [String[]]
    [System.IO.FileInfo[]]
.OUTPUTS
    [HtmlAgilityPack.HtmlDocument]
    [HtmlAgilityPack.HtmlNode]
.NOTES
    General notes
#>
function ConvertFrom-Html {
    [CmdletBinding(DefaultParameterSetName="String")]
    param (
        #The HTML text to parse. Accepts multiple separate documents as an array. This also accepts pipeline from Invoke-WebRequest
        [Parameter(ParameterSetName="String",Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [String[]]$Content,

        #The URI or URIs from which to retrieve content. This may be faster than using Invoke-WebRequest but is less flexible in the method of retrieval (for instance, no POST)
        [Parameter(ParameterSetName="URI",Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [System.URI[]]$URI,

        #Path to file or files containing HTML content to convert. This accepts pipeline from Get-Childitem or Get-Item
        [Parameter(ParameterSetName="Path",Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [System.IO.FileInfo[]]$Path,

        #Do not return the Linq documentnode, instead return the HTMLDocument object. This is useful if you want to do XPath queries instead of Linq queries
        [switch]$Raw

    )

    begin {
    }

    process {
        #Find the type of input and bind it to inputObject
        $inputObject = $null
        foreach ($contentType in "Content","URI","Path") {
            if ((Get-Variable -erroraction SilentlyContinue $contentType).value) {
                $inputObject = (Get-Variable $contentType).value
                break
            }
        }
        if (-not $inputObject) {write-error "Input Object Type Not Identified. If you see this then ConvertFrom-HTML needs better input validation"}

        #Unwrap any arrays. This allows us to accept both pipeline and parameter input
        $inputObject | ForEach-Object {
            $inputItem = $PSItem
            $htmlDoc = new-object HtmlAgilityPack.HtmlDocument

            #Process all object types into a common HTML document format
            switch ($inputItem.GetType().FullName) {
                "System.String" {
                    $htmlDoc.LoadHtml($inputItem)
                }
                "System.Uri" {
                    $htmlDoc = (new-object HtmlAgilityPack.HtmlWeb).Load($inputItem)
                }
                "System.IO.FileInfo" {
                    $htmlDoc.Load($inputItem)
                }
                Default {
                    write-error "Object Type not supported or implemented. If you see this error then ConvertFrom-HTML has improper input validation"
                    continue
                }
            }
            if ($inputItem) {
                if ($Raw) {
                    $htmlDoc
                } else {
                    $htmlDoc.DocumentNode
                }
            }
        }

    }
}