#generate SiteReportcontaining all Folder, ListItems with its Size in KB

#$loc = "C:\Users\b943vn\source\CSOM" # Location of DLL's
#Set-Location $loc

#Add-Type -Path (Resolve-Path "Microsoft.SharePoint.Client.dll")
#Add-Type -Path (Resolve-Path "Microsoft.SharePoint.Client.Runtime.dll")

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"


function retrieveListItems($_web)
{
   
    #get all listItems
    #$listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
    
    try
    {
        Write-host "Processing Web :"$_web.URL
        $listCollection=$_web.Lists;
        $ctx.Load($listCollection);
        $ctx.ExecuteQuery();


        foreach ($list in $listCollection)
        {
            $ctx.Load($list)
            $ctx.Load($list.RootFolder)
            $ctx.ExecuteQuery()
            $weburl= $ctx.Web.ServerRelativeUrl
            $listUrl =$("{0}{1}" -f $ctx.Web.Url.Replace($ctx.Web.ServerRelativeUrl,''), $list.RootFolder.ServerRelativeUrl)
            

           if($list.Hidden -ne "true" -and $list.IsCatalog -ne "true" -and  $list.BaseType -eq "DocumentLibrary")
           {          
                
                "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $list.Title, $list.BaseType, $list.RootFolder.ServerRelativeUrl,$list.Title,'', $list.LastItemModifiedDate, $list.ItemCount | Out-File -FilePath $outputFile -Append 
                 Write-host $list.Title
                
                <#$camlQuery=New-Object Microsoft.SharePoint.Client.CamlQuery
                
                #get only folders from list
                $camlQuery.ViewXml="@
                <View>
                    <Query>
                        <Where>
                            <Eq>
                                <FieldRef Name='FSObjType'/><Value Type='Integer'>1</Value>
                            </Eq>
                        </Where>
                    </Query>
                </View>"

                $listItems=$list.GetItems($camlQuery); #>

                $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
             $camlQuery.ViewXml ="<View Scope='RecursiveAll' />";
             $listItems=$list.GetItems($camlQuery)

                #$listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
                
                $ctx.Load($listItems);
                $ctx.ExecuteQuery();
    

                foreach($listItem in $listItems)
                {                    
                     
                   #check if ListItem is Folder or File
                    if($listItem["FSObjType"] -eq 1)
                    {                    
                        $folderSize= GetFolderSize($listItem.Folder)   
                        
                       # $sizeMB = (($folderSize)/1000000) 

                        $value = [math]::Round(($folderSize/1024),2)
                        $sizeKB = "{0:N2}" -f $value
                        
                        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $listItem["FileLeafRef"],'Folder',$listItem["FileRef"],$list.Title,$sizeKB,$listItem["Modified"],$listItem["ItemChildCount"] | Out-File -FilePath $outputFile -Append
                    }
                    else
                    {
                        #$sizeMB = (($listitem["File_x0020_Size"])/1000000)

                        $value = [math]::Round(($folderSize/1024),2)
                        $sizeKB = "{0:N2}" -f $value
                        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $listItem["FileLeafRef"],'ListItem',$listItem["FileRef"],$list.Title,$sizeKB,$listItem["Modified"],$listItem["ItemChildCount"] | Out-File -FilePath $outputFile -Append
                    }
                }   
 
            }     
        }
        <#if($_web.Webs.Count -gt 0) 
	    {
             foreach($subSite in $_web.Webs)
            { 
                
               $ctx.Load($subSite)
               $ctx.Load($subSite.Webs)
               $ctx.ExecuteQuery()
             
             $size = GetWebSize($subSite)  
             $sizeMB = "{0:N2}" -f (($size)/1MB)

               "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $subSite.Title, 'Site', $subSite.ServerRelative,'',$sizeMB, $subSite.LastItemModifiedDate, $subSite.ItemCount | Out-File -FilePath $outputFile -Append 
               retrieveListItems($subSite) 
             }
         }#>
       $ctx.Dispose()
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        #exit
    }
   
}

function GetWebSize ($web)  
{  
    $ctx.Load($web.Folders) 
    $ctx.ExecuteQuery() 
    [long]$total = 0  
    foreach ($folder in $web.Folders) {  
        $total += GetFolderSize -Folder $folder  
    }          
    return $total  
}  
  
function GetFolderSize ($folder)  
{  
    $ctx.Load($folder.Files) 
    $ctx.Load($folder.Folders) 
    $ctx.ExecuteQuery(); 
    [long]$folderSize = 0   
    foreach ($file in $folder.Files | Where {-Not($_.Name.EndsWith(".aspx"))}) { 
        $folderSize += $file.Length;  
    }  
    foreach ($fd in $folder.Folders) {  
        $folderSize += GetFolderSize -Folder $fd  
    }  
    return $folderSize  
}  


function generateSiteDataReports
{
    try
    {
        
       # $siteCollectionUrl= Read-Host -Prompt "Enter Site Collection URL"

        #$Username =  Read-Host -Prompt "Enter userName: ";

        #$password = Read-Host -Prompt "Enter password: " -AsSecureString ;

        $siteCollectionUrl= "https://tfssharepoint.company.com/sites/DefaultCollection/<ProjectName>"

        $Username =  "<Domain>\<User>";

        $password = "India2019$"

        $logFile = "$PSScriptRoot\log.txt"

        if(Test-Path $logFile)
        {
            Remove-Item $logFile
        }

        $outputFile = "$PSScriptRoot\SiteReport.csv"

        # Remove existing output file
        if(Test-Path $outputFile)
        {
             Remove-Item $outputFile
        }


        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f "Title", "Object Type", "URL","ListName","Size", "Modified", "ItemCount" | Out-File -FilePath $outputFile -Append
        $ctx=New-Object Microsoft.SharePoint.Client.ClientContext($SiteCollectionUrl);
        $ctx.Credentials=New-Object System.Net.NetworkCredential($Username, $password);

        $ettkundWeb=$ctx.Web
        $ctx.Load($ettkundWeb)
        $ctx.Load($ettkundWeb.Webs)
        $ctx.ExecuteQuery()

        #Get Web Size
      # $size = GetWebSize($ettkundWeb)  
        $sizeMB = (($size)/1048576)  
        $sizeGB = "{0:N2}" -f (($size)/1GB) 

        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $ettkundWeb.Title, 'Site', $ettkundWeb.ServerRelativeUrl,'',"", $ettkundWeb.LastItemModifiedDate, $subSite.ItemCount | Out-File -FilePath $outputFile -Append 

        Write-host "Processing Web :"   $ettkundWeb.URL
        retrieveListItems($ettkundWeb)
       
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }

}

generateSiteDataReports
