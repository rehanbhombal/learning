Add-PSSnapin "Microsoft.SharePoint.PowerShell"


$urlWeb="https://tfssharepoint.company.com/sites/DefaultCollection/<ProjectName>"
Get-SPUser -Web $urlWeb -Limit ALL| Where { $_.IsDomainGroup } | select Email, @{name=”Exlicit given roles”;expression={$_.Roles}}, @{name=”Roles given via groups”;expression={$_.Groups | %{$_.Roles}}},Groups 