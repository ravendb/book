RavenDB book?
=============

To create the build, run .\build.ps1 and then look in the Output directory.


Create *.mobi file for Amazon Kindle 
=============
1. Download [Amazon's KindleGen](http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000234621) and extract it anywhere on your PC
2. Execute 'Set-Alias -Name kindlegen -Value <Path to your exe>' in Powershell, for example 'Set-Alias -Name kindlegen -Value C:\KindleGen\kindlegen.exe'
3. Execute mobi.ps1 and then look in the Output directory
