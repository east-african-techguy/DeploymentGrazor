# DeploymentGrazor

Used to discover secrets in insecure Azure Deployments          

## Description
----------------------

Azure deployment templates are static files stored in your tenant used to describe instantiated resources. When infrastructure as code tools such as bicep or terraform are used without either the @secure or "sensitive" decorators. This could result in secrets being exposed in clear text from deployment settings in Azure portal. To automate the process of discovering such secrets the DeploymentGrazor tool was created.  This tool expounds on the following Az PowerShell command:

~~~
Get-AzResourceGroupDeployment -ResourceGroupName <resourceGroupName>
~~~


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

1) Download/sync locally the script file templateScan.ps1 and DeploymentGrazor.ps1
2) Open PowerShell in the Deployment Grazor folder with the permission to run scripts:
   "powershell -ExecutionPolicy Bypass -NoProfile"
3) Import-Module ./DeploymentGrazor.ps1
4) Run Start-DeploymentScan  
