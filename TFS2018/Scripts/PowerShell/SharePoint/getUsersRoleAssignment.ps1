$cred=Get-Credential
Connect-PnPOnline -Url https://internwebbst.company.com -Credential $cred
$users= Get-PnPUser -WithRightsAssigned
foreach($user in $users)  
{  
    $check=$user.IsDomainGroup
    if($_.IsDomainGroup){
        write-host -ForegroundColor Green "Getting SCA from site: " $user.Title  
    }
    else
    {
        Write-Host $user.Title
    }
    
 }
