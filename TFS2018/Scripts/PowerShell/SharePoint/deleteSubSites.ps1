#Delete All subsites from particular Site collection

Add-PSSnapin "Microsoft.SharePoint.PowerShell"



$url = "http://e75lanws0898v:31864/sites/DefaultCollection"
$subsites = (Get-SPSite $url).allwebs | ?{$_.url -like $url +"/*"}

foreach($subsite in $subsites) { 

if($subsite.url -ne "http://e75lanws0898v:31864/sites/DefaultCollection/SubSite2Delete")
{
    Remove-SPWeb $subsite.url 
}


}