# Define input parameters
param
(
	[string]$zippath = $(throw "Zip path must be provided."),
	[string]$outputpath = $(throw "Output path must be provided.")
)

# check if output path exists, else unzip will be skipped.
if(test-path $outputpath)
{
	Expand-Archive -Path $zippath -DestinationPath $outputpath
}
else
{
	Write-Host "Output Path does not exist."
}