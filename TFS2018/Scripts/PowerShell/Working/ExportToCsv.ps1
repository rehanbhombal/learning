$outputFile = "$PSScriptRoot\tasks.csv"
    
# Remove existing output file
if(Test-Path $outputFile)
{
    Remove-Item $outputFile
}
"{0}`t{1}`t{2}`t{3}" -f "Name", "Description", "Category", "Version" | Out-File -FilePath $outputFile