<#

###########################################################################################
#                                                                                         #
#    Deployment Grazor - Used to discover secrets in insecure Azure Deployments           #
#                                                                                         #
###########################################################################################
#                                                                                         #
#                                                                                         #
#                             Written by: Javan Joshua Mnjama                             #
#                                  @east-african-techguy                                  #
#                                                                                         #
#                                                                                         #
###########################################################################################


Versions Notes:
Version 1.0 - 04-06-22


###########################################################################################

HOW TO INSTALL AZURE POWERSHELL MODULE:

Guide for installing Azure "AZ" PowerShell Module:
https://docs.microsoft.com/en-us/powershell/azure/install-az-ps



If local admin (PowerShell command):
    Install-Module -Name Az -AllowClobber
    Install-Module AzureAD -AllowClobber
Else:
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
    Install-Module AzureAD -AllowClobber -Scope CurrentUser
    
###########################################################################################

HOW TO RUN Deployment Grazor:

1) Download/sync locally the script file templateScan.ps1
2) Open PowerShell in the Deployment Grazor folder with the permission to run scripts:
   "powershell -ExecutionPolicy Bypass -NoProfile"
3) Import-Module ./DeploymentGrazor.ps1
4.) Run Start-DeploymentScan  

#>


$DeploymentGrazorVersion = "v1.0"

$DeploymentGrazor = @"

-------------------------------------------------------------------------------
 
____  _____ ____  _     _____   ____  __ _____ _   _ _____ 
|  _ \| ____|  _ \| |   / _ \ \ / /  \/  | ____| \ | |_   _|
| | | |  _| | |_) | |  | | | \ V /| |\/| |  _| |  \| | | |  
| |_| | |___|  __/| |__| |_| || | | |  | | |___| |\  | | |  
|____/|_____|_|   |_____\___/ |_| |_|  |_|_____|_| \_| |_|  
                                                            
  ____ ____      _     ________  ____  
 / ___|  _ \    / \   |__  / _ \|  _ \ 
| |  _| |_) |  / _ \    / / | | | |_) |
| |_| |  _ <  / ___ \  / /| |_| |  _ < 
 \____|_| \_\/_/   \_\/____\___/|_| \_\

                                                                
"@                                   

$Author = @"
-------------------------------------------------------------------------------

                        Author: Javan Joshua Mnjama
                            @east-african-techguy 
                         

-------------------------------------------------------------------------------

"@


Write-Output $DeploymentGrazor
Write-Output "`n                  ***   Welcome to Deployment Grazor $DeploymentGrazorVersion   ***`n"
Write-Output "`n                  ***   Used to discover secrets in insecure Azure Deployments :)`n"
Write-Output $Author


function Start-DeploymentScan{
    Write-Host "Importing the scanning module with: `"Import-Module `".\templateScan.ps1`" -force `" command" -ForegroundColor Green
    Import-Module ".\templateScan.ps1" -force
    Write-Host "Starting the scan with: `"Scan-DeploymentTemplates`" command`n" -ForegroundColor Green
    Scan-Templates
}

