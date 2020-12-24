<# Script: BackupWITD
Author: Rehan Bhombal 
Date: 15/11/2019
Description: Script to backup all Work Item Type Definitions of Team Projects per collection. 
Usage: .\BackupWITD.ps1 'https://tfs2018/tfs' #>

param
(
    [Parameter(Mandatory=$false)][string] $tfsServer = 'https://tfs2018/tfs'
)

$apiVersion = "api-version=2.0" 
$logFile = "$PSScriptRoot\log.txt"
$dirName = (Get-Date).tostring("yyyyMMdd-hhmmss")
New-Item -itemType Directory -Path $PSScriptRoot -Name $dirName

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

# Get Collections
function GetCollections
{
    param
    (
        [Parameter(Mandatory=$true)][string] $tfsServer
    )
    try
    {
        $tfsServerApiUrl = $tfsServer + '/_apis/projectCollections'
        #Write-Host $tfsServerApiUrl
        $tfsServerObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsServerApiUrl -ErrorAction Stop
        #Write-Host $tfsServerObject
        $collections = $tfsServerObject.value.name
        #Write-Host $collections
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $collections
}

# Get Projects
function GetProjects
{
    param
    (
        [Parameter(Mandatory=$true)][string] $collection
    )
    try
    {
        $tfsProjectsApiUrl = "$($tfsServer)/$($collection)/_apis/projects/?$($apiversion)&`$top=500"
        #Write-Host $tfsProjectsApiUrl
        $tfsProjectObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectsApiUrl -ErrorAction Stop
        #Write-Host $tfsProjectObject
        $projects = $tfsProjectObject.value.name
        #Write-Host $projects
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $projects
}

# Get Work Item Types
function GetWorkItemTypes
{
    param
    (
        [Parameter(Mandatory=$true)][string] $collection,
        [Parameter(Mandatory=$true)][string] $project
    )
    try
    {
        $tfsProjectWITApiUrl = "$($tfsServer)/$($collection)/$($project)/_apis/wit/workitemtypes?api-version=4.1"
        #Write-Host $tfsProjectsApiUrl
        $tfsProjectWITObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectWITApiUrl -ErrorAction Stop
        $jsser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $jsser.MaxJsonLength = $jsser.MaxJsonLength * 10
        $jsser.RecursionLimit = 99    
        $witObject = $jsser.DeserializeObject($tfsProjectWITObject)
        Write-Host $witObject
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $witObject
}

# Invoke witadmin application
function Invoke-TFSWITAdmin
{
    param 
    ( 
        [string] $Arguments 
    )

    $WITAdminPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\WitAdmin.exe'

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo

    $pinfo.FileName = $WITAdminPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $Arguments

    Write-Verbose ('Executing shell command: WitAdmin.exe {0}' -f $Arguments)

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    Write-Debug "stdout: $stdout"
    Write-Debug "stderr: $stderr"

    $executionResultObject = New-Object PSObject -Property @{ 
        StandardOutput         = $stdout  
        StandardErrorOutput    = $stderr
        ExitCode               = $p.ExitCode
    }

    Write-Output $executionResultObject

}

# Run export witadmin
function Invoke-TFSWITAdmin-ExportWITD
{
    [CmdletBinding()]
    param ( 
        [string] $TFSProjectCollectionUrl = 'https://tfs2018/tfs/DefaultCollection',
        [Parameter(ValueFromPipeline=$true)][string] $Project,
        [string] $TypeName,
        [string] $FileName,
        [string] $Encoding,
        [switch] $ExportGlobalLists      
    )  
            
    process
    {
        $Arguments = 'exportwitd /collection:"{0}" /p:"{1}" /n:"{2}" /f:"{3}"' -f $TFSProjectCollectionUrl, $Project, $TypeName, $FileName
        if ($Encoding) { $Arguments = $Arguments + (' /e:"{0}"' -f $Encoding) }
        if ($ExportGlobalLists.IsPresent) { $Arguments = $Arguments + ' /exportgloballists'}
            
        $result = Invoke-TFSWITAdmin -Arguments $Arguments

        $actionLogObject = New-Object PSObject -Property @{ 
            ExitCode            = $result.ExitCode
            Project             = $Project
            FileName            = $FileName
            ActionText          = $null
            Status              = $null
            StandardOutput      = $result.StandardOutput -replace "`t|`n|`r",''
            StandardErrorOutput = $result.StandardErrorOutput -replace "`t|`n|`r",''
            Timestamp           = (Get-Date).ToString()
        }   
                        
        if ($result.StandardOutput) 
        {
            $actionLogObject.ActionText = 'Sucessfully exported work item "{0}" into file "{1}".' -f $TypeName, $FileName
            $actionLogObject.Status = 'OK'
            Write-Verbose ($actionLogObject.ActionText)
        }
        else
        {
            $actionLogObject.ActionText = 'Error exporting work item "{0}" into file "{1}".' -f $TypeName, $FileName
            $actionLogObject.Status = 'Error'
            Write-Verbose ($actionLogObject.ActionText)
        } 
                    
        Write-Output($actionLogObject)         

    }
             
}

try
{
    $colls = GetCollections -tfsServer $tfsServer
    foreach($coll in $colls)
    {
        If(!(test-path $coll))
        {
            New-Item -ItemType Directory -Force -Path $dirName\$coll
        }
        $projs = GetProjects -collection $coll

        foreach ($proj in $projs)
        {
            If(!(test-path $coll\$proj))
            {
                New-Item -ItemType Directory -Force -Path $dirName\$coll\$proj
            }
            $witds = GetWorkItemTypes $coll $proj
            foreach ($witd in $witds.value)
            {
                $witName = $witd.name
                $filePath = ".\$dirName\$coll\$proj\$proj.$witName.xml"
                Invoke-TFSWITAdmin-ExportWITD $tfsServer/$coll $proj $witName $filePath
                #Write-Host "WIT:" $witd.name -ForegroundColor White
            }
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}

#https://tfs2018/tfs/DefaultCollection/<ProjectName>/_apis/wit/workitemtypes?api-version=4.1