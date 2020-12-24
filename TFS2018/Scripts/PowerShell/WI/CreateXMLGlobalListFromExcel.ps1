<# Script: Moves values from Excel to the Global List XML format. 
Author: Rehan Bhombal 
Date: 01/07/2019
Description: Script to move global list values from excel to xml. 
Usage: .\CreateXMLGlobalListFromExcel.ps1 PathToExcel GlobalListName 
Excel Format: All the Global List values must be in the first column of the sheet named 'Sheet1'#>

param
(
    [Parameter(Mandatory=$true)][string] $pathToExcel,
	[Parameter(Mandatory=$true)][string] $globalListName
)
$a = New-Object -comobject Excel.Application
$a.Visible = $true
$a.DisplayAlerts = $False

$Workbook = $a.workbooks.open($pathToExcel)
$Sheet = $Workbook.Worksheets.Item("Blad1")

$row            = [int]2
$KN             = @() # beginnt bei 2,1... 3,1... 4,1
Do {$KN        += $Sheet.Cells.Item($row,1).Text ; $row = $row + [int]1} until (!$Sheet.Cells.Item($row,1).Text)

$Workbook.Close()
$a.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($a) | Out-Null

[xml]$Doc = New-Object System.Xml.XmlDocument
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$doc.AppendChild($dec) | Out-Null
$text = @"
Generated on $(Get-Date)
"@
$doc.AppendChild($doc.CreateComment($text)) | Out-Null
$root = $doc.CreateNode("element","gl:GLOBALLISTS",$null)
$root.SetAttribute("xmlns:gl","http://schemas.microsoft.com/VisualStudio/2005/workitemtracking/globallists")
$c = $doc.CreateNode("element","GLOBALLIST",$null)
$c.SetAttribute("name",$globalListName)
$KN = $KN | Sort -Unique
foreach($member in $KN)
{
    $e = $doc.CreateElement("LISTITEM")
    $e.SetAttribute("value",$member)
    $c.AppendChild($e) | Out-Null
}
#append to root
$root.AppendChild($c) | Out-Null
#add root to the document
$doc.AppendChild($root) | Out-Null
$doc.save("$PSScriptRoot\DefaultCollection_<ProjectName>_GlobalList.xml")