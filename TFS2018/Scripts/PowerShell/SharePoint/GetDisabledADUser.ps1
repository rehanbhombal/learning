$cred=Get-Credential
Connect-PnPOnline -Url https://internwebbst.company.com/sites/internwebbforvaltning/bestallningar -Credential $cred

$disabledUsers = @()


function getDisabledUsersId
{
    try
    {
        $listItems= (Get-PnPListItem -List 51186f37-8289-4f94-b104-59d6d0a293a2 -Fields "Best_x00e4_llaren") 
        foreach($listItem in $listItems){  
  
           $User=$listItem["Best_x00e4_llaren"] 
           $Owners = $User.LookupValue    
 
            foreach($Owner in $Owners)
            {
                $UserId= $Owner.substring($Owner.IndexOf("\")+1)
                $userAD = Get-ADUser -Filter{SamAccountName -Like $UserId}
               if(!$userAD.enabled)
               {
                    $disabledUsers+=$UserId
               }
            }
    
        } 
        Write-Host $listItems.count
        if($disabledUsers.Length -ne 0)
        {
            SendEmail($disabledUsers)
        }
    }
    catch
    {        
         Write-Host "Operation Failed! Reason:"$_.Exception.Message.ToString()
    }
}

function SendEmail($disabledUsers)
{
    try
    {
        $To=@("<EmailAddress>","<EmailAddress>")        
        $Body=@() 
        $Body+="Following Users are not Active:"
        $Subject="Disabled Users"
        foreach($disabledUser in $disabledUsers)
        {
            $Body+=,@($disabledUser)
            $body+=","
        } 
   
    #$Body=$Body |
       # ConvertTo-Html -Fragment -PreContent '<p>Following Users are not Active:</p>' |
       # Out-String
      
       Send-PnPMail -To $To -Subject $Subject -Body ($Body | Out-String)
      
    }
    catch
    {        
         Write-Host "Email sent: Failed! Reason:"$_.Exception.Message.ToString()
    }
}


getDisabledUsersId