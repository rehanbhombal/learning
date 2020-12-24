

$tfsServer = 'https://tfs2018/tfs/'
$collectionName = 'DefaultCollection'
$apiVersionTag = "api-version=4.1"
$searchString = '*E75LAPWP1035V*'
[string]$date = "{0:yyyy.MM.dd}" -f (get-date)
$FilePrefix = ($PSScriptRoot+"\"+$PSCommandPath.split('\.')[-2] )  #shared common filename path without extension
$Global:PathToExceptionsLog = $FilePrefix+".err.log" #errors log
$Global:logFile = "$FilePrefix.ActivityLog.log"

function GetProjects
{
    param (
        [Parameter(Mandatory=$true)][string]$collectionName
        )
    # Construct the Get list of team projects url
    $getProjectsUrl = "$($tfsServer)/$($collectionName)/_apis/projects/?$($apiVersionTag)&`$top=1000"
    Write-Debug "Get Projects for $getProjectsUrl"
    # Call the REST API using Invoke-RestMethod. -UseDefaultCredentials for using windows authentication
    $json = Invoke-RestMethod -UseDefaultCredentials -uri $getProjectsUrl
    $formatedJson =  $json | Format-List
    # Write-Debug $formatedJson
    return $json.value | sort -Property name
}

function GetBuildDefinitions
{
    param ( 
        [Parameter(Mandatory=$true)][string]$collectionName,
        [Parameter(Mandatory=$true)][string]$projectName
        )

    $definitionsOverviewUrl = "$tfsServer/$collectionName/$projectName/_apis/build/definitions?$($apiVersionTag)"
    Write-Debug "Getting Build Definitions for $definitionsOverviewUrl"
    $definitionsOverviewResponse = Invoke-RestMethod -UseDefaultCredentials -Uri $definitionsOverviewUrl
    return $definitionsOverviewResponse.value
}

<#$projects = GetProjects -collectionName $collectionName
foreach ($project in $projects)
{#>
    $definitions = GetBuildDefinitions -collectionName $collectionName -projectName 'Halsa'
    foreach ($definition in $definitions | where { $_.type -ne "xaml" } ) #check only new builds
    {
        $definitionDetails = Invoke-RestMethod -UseDefaultCredentials -uri $definition.url
        $buildVariables = $definitionDetails.variables | % {$_}
        foreach($var in $buildVariables)
        {
            Write-Host $var
        }
    }
#}