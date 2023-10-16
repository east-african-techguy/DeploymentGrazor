# DeploymentGrazor

Used to discover secrets in insecure Azure Deployments          

## Description


Azure deployment templates are static files stored in your tenant used to describe instantiated resources. When infrastructure as code tools such as bicep or terraform are used without either the @secure or "sensitive" decorators. This could result in secrets being exposed in clear text from deployment settings in Azure portal. To automate the process of discovering such secrets the DeploymentGrazor tool was created.  This tool automates the [AZT605.3](https://microsoft.github.io/Azure-Threat-Research-Matrix/CredentialAccess/AZT605/AZT605-3/) threat outlined on the Azure Threat Matrix

<img width="1172" alt="azure threat matrix" src="https://github.com/east-african-techguy/DeploymentGrazor/assets/92095548/7380ce75-9c5e-453d-bce4-63b6bf9ec419">


Versions Notes:
Version 1.0 - 04-06-22


### How to install the Azure PowerShell Module:

Guide for installing Azure "AZ" PowerShell Module:
https://docs.microsoft.com/en-us/powershell/azure/install-az-ps



If local admin (PowerShell command):
    Install-Module -Name Az -AllowClobber
    Install-Module AzureAD -AllowClobber
Else:
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
    Install-Module AzureAD -AllowClobber -Scope CurrentUser
    

### How to run Deployment Grazor:

1) Download/sync locally the script file templateScan.ps1 and DeploymentGrazor.ps1
2) Open PowerShell in the Deployment Grazor folder with the permission to run scripts:
   "powershell -ExecutionPolicy Bypass -NoProfile"
3) Import-Module ./DeploymentGrazor.ps1
4) Run Start-DeploymentScan
5) Results of scan will be written in a txt file in the directory used to execute the script  
