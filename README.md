# DeploymentGrazor


###########################################################################################
#                                                                                         #
#                        Used to discover secrets in insecure Azure Deployments           #
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
4) Run Start-DeploymentScan  
