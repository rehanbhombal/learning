#Get Group,user,AD group name etc with Access level(Read,Edit etc)

$cred = get-credential
Connect-PnPOnline -Url "https://tfssharepoint.company.com/sites/DefaultCollection/<ProjectName>" -Credentials $cred
$web = Get-PnPWeb -Includes RoleAssignments
foreach($ra in $web.RoleAssignments) {
    $member = $ra.Member
    $loginName = get-pnpproperty -ClientObject $member -Property LoginName
     
     $TitleN=Get-PnPProperty -ClientObject $ra -Property Member
     $type=$ra.Member.PrincipalType.ToString()
    $title=$ra.Member.Title
     write-host $type
    $rolebindings = get-pnpproperty -ClientObject $ra -Property RoleDefinitionBindings
    write-host "$($title)--$($loginName) - $($rolebindings.Name)"
    write-host
    
}