<#

###########################################################################################
#                                                                                         #
#    Deployment Grazor - Used to discover secrets in insecure Azure Deployments           #
#                                                                                         #
###########################################################################################
#                                                                                         #
#                                                                                         #
#                             Written by: Javan Joshua Mnjama                             #
#                                 @east-african-techguy                                   #
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


# Check if the PowerShell Azure Module exists on the machine
function Check-AzureModule {
    $oneAzureModuleExist = $true
    # Try loading the AZ PowerShell Module
    try {
        $azModule = Get-InstalledModule -Name Az -ErrorAction Stop
    }
    Catch {
        Write-Host "`nCouldn't find the Azure `"AZ`" PowerShell Module" -ForegroundColor Yellow
        Write-Host "The tool will prompt you and install it using the `"Install-Module -Name Az`" command" -ForegroundColor Yellow
        if ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
            Install-Module -Name Az -AllowClobber
        }
        else {
            Install-Module -Name Az -AllowClobber -Scope CurrentUser
        }
    }
    try {
        $azModule = Get-InstalledModule -Name Az -ErrorAction Stop
        if ($azModule) {
            Write-Host "`n  [+] Great, Azure `"AZ`" PowerShell Module exists`n"   
        }
    }
    catch {
        Write-Host "`nEncountered an error - couldn't find the Azure `"AZ`" PowerShell Module" -BackgroundColor Red
        Write-Host "Please install Azure Az PowerShell Module (requires PowerShell version 5.1+)" -BackgroundColor Red
        Write-Host "Installation guideline:" -BackgroundColor Red
        Write-Host "https://docs.microsoft.com/en-us/powershell/azure/install-az-ps" -BackgroundColor Red
        $oneAzureModuleExist = $false
        
    }



}


# Connect to the target Azure environment
function Connect-AzureEnvironment {
    
    try {
        $answer = "n"
        $AzContext = Get-AzContext  | Where-Object { ($_.tenant) -or ($_.TenantId) }
        if ($AzContext.Account) {
            Write-Host "The current Azure account context is set for:"
            Write-Host ($AzContext | select  Name, Account, Environment | Format-List | Out-String)  -NoNewline
            $answer = Read-Host "Do you want to use this Azure Account context? Press (y/Y or n/N)"
        }
        if ($answer.ToLower() -notmatch "y") {
            $AzAllCachedContext = Get-AzContext -ListAvailable
            $AzCachedContext = $AzAllCachedContext | Where-Object { ($_.Tenant) -or ($_.TenantId) }
            if ($AzCachedContext) {
                Write-Host "The follwoing Azure user/s are available through the cache:`n"
                $counter = 0
                $AzCachedContext | foreach {
                    $counter++
                    $contextAccount = $_.Account.id 
                    $contextName = $_.Name
                    $contextNameEx = "*" + $contextAccount + "*"
                    if ($contextName -like $contextNameEx) {
                        Write-Host "$counter) Name: $contextName"
                    }
                    else {
                        Write-Host "$counter) Name: $contextName - $contextAccount"
                    }
                
                }
                $contextAnswer = Read-Host "`n Do you want to use one of the above cached users?`nPress the user's number from above (or n/N for chosing a new user)"
                if ($contextAnswer.ToString() -le $counter) {
                    $contextNum = [int]$contextAnswer
                    $contextNum--
                    $chosenAccount = $AzCachedContext[$contextNum].Account.id
                    Write-Host "`nYou chose to proceed with $chosenAccount"
                    Set-AzContext -Context $AzCachedContext[$contextNum] -ErrorAction Stop  > $null
                    return $true
                }
            }
            Write-Host "Please connect to your desired Azure environment"
            Write-Host "These are the available Azure environments:"
            $AzEnvironment = Get-AzEnvironment | select Name, ResourceManagerUrl
            Write-Host ($AzEnvironment | Format-Table | Out-String)  -NoNewline
            $answer = read-host "Do you use the US-based `"AzureCloud`" environment? Press (y/Y or n/N)"
            $rand = Get-Random -Maximum 10000
            if ($answer.ToLower() -match "y") {
                Connect-AzAccount -ContextName "Azure$rand" -ErrorAction Stop > $null
            }
            else {
                $AzEnvironment = Read-Host "Ok, please write your Azure environment Name from the list above.`nAzure environment Name"
                Connect-AzAccount -ContextName "Azure$rand" -Environment $AzEnvironment -ErrorAction Stop > $null
            }    
        }
    }
    catch {
        Write-Host "Encountered an error - check again the inserted Azure Credentials" -BackgroundColor red
        Write-Host "There was a problem when trying to access the target Azure Tenant\Subscription" -BackgroundColor Red
        Write-Host "Please try again... and use a valid Azure user" 
        Write-Host "You can also try different Azure user credentials or test the scan on a different environment"
        return $false
    }
    Write-Host "`n  [+] Got valid Azure credentials"

    return $true
}


# Main Function to Scan Deployment Templates

function Run-SubscriptionScan {
    $count = 0
    $deploymentCount = 0
    # Secret Test Cases to check in deployment templates
    $secretTestCases = 'authkey', 'instrumentationkey', 'password', 'clientsecret', 'connectionstring'

    foreach ($id in $subscriptionList) {
        $resourceGroup = Get-AzResourceGroup
        
        while ($count -lt $resourceGroup.count) {

            # Pulls all the deployment template from a resource group        
            $deployment = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroup[$count].ResourceGroupName


            if ($deployment) {
                
                while ($deploymentCount -lt $deployment.Count) {
                
                                          
                    $Parameters_Secret_Collection = $deployment[$deploymentCount]
            
                    # This checks for secrets in the parameters section of deployments templates
                    foreach ($parData in $Parameters_Secret_Collection) {
                        if ( $parData.Parameters) {                      
                            foreach ($key in $parData.Parameters) {
                                foreach ($i in $key.Keys) {
                                    foreach ($item in $secretTestCases) {                                        
                                       # This checks for secrets using the secrets test cases. $secretVal is used to elimate secureStrings
                                       $secretVal = $key[$i].Type
                                       if (($i.ToLowerInvariant() -like "*" + $item + "*") -and ($secretVal -eq 'String')) {

                                            Write-Output "===============================================================================" | Out-File -Append "./demo.txt"  
                                            Write-Output "Subscription ID :" $id | Out-File -Append "./demo.txt"  
                                            Write-Output "===============================================================================" | Out-File -Append "./demo.txt"  

                                            Write-Output "==============================================" | Out-File -Append "./demo.txt"  
                                            Write-Output "ResourceGroup ..." $resourceGroup[$count].ResourceGroupName | Out-File -Append "./demo.txt"  
                                            Write-Output "==============================================" | Out-File -Append "./demo.txt"  

                                            Write-Output "==============================================" | Out-File -Append "./demo.txt"  
                                            Write-Output " Secret in Deployment Template" $Deployment[$deploymentCount].DeploymentName | Out-File -Append "./demo.txt"   
                                            Write-Output "==============================================" | Out-File -Append "./demo.txt" 

                                            # writes output and appends to file
                                            Write-Output $i : $key[$i].Value | Out-File -Append "./demo.txt"  
                                        }
                                    }
                           
                                }
                            }         
                        } 
                    }
            
            
                    # Outputs Secret Check

                    $Outputs_Secrets_Collection = $deployment[$deploymentCount].Outputs

            
                    foreach ($data in $Outputs_Secrets_Collection) {
                        foreach ($item in $secretTestCases) {
                            if ($data.Keys -like "*" + $item + "*") {

                                Write-Output "===============================================================================" | Out-File -Append "./demo.txt"  
                                Write-Output "Subscription ID :" $id | Out-File -Append "./demo.txt"  
                                Write-Output "===============================================================================" | Out-File -Append "./demo.txt"  


                                Write-Output "==============================================" | Out-File -Append "./demo.txt"  
                                Write-Output "ResourceGroup ..." $resourceGroup[$count].ResourceGroupName | Out-File -Append "./demo.txt"  
                                Write-Output "==============================================" | Out-File -Append "./demo.txt"  

                                Write-Output "==============================================" | Out-File -Append "./demo.txt"  
                                Write-Output " Secret in Deployment Template" $Deployment[$deploymentCount].DeploymentName | Out-File -Append "./demo.txt"   
                                Write-Output "==============================================" | Out-File -Append "./demo.txt" 



                                Write-Output $data.Keys ":" $data.Values | Out-File -Append "./demo.txt"                   
                            }
                        }
                    
                    } 
                        
   
                    $deploymentCount ++
                }

            }
            $count ++
        }

    
    
    #    Write-Output "Output written to file ./demo.txt"
    }
}

function Scan-Templates {
    [CmdletBinding()]
    param(
        [switch]
        $UseCurrentCred,
        [string]
        $ScanSubscriptionId
    )

    $CloudShellMode = $false
    try {
        $cloudShellRun = Get-CloudDrive
        if ($cloudShellRun) {
            $CloudShellMode = $true
        }
    }
    catch {
        $CloudShellMode = $false
    }
    $AzModule = $true
    if (-not $CloudShellMode) {
        $AzModule = Check-AzureModule
    }
    if ($AzModule -eq $false) {
        Return
    }
    if (-not $UseCurrentCred) {
        $AzConnection = Connect-AzureEnvironment
        if ($AzConnection -eq $false) {
            Return
        }
        $currentAzContext = Get-AzContext
    }
    else {
        $currentAzContext = Get-AzContext
    }
    if ($CloudShellMode) {
        try {
            Connect-AzureADservice
        }
        catch {
            Write-Host "Couldn't connect using the `"Connect-AzureADservice`" API call,`nThe tool will connect with `"Connect-AzureActiveDirectory `" call"
            $AzConnection = Connect-AzureActiveDirectory -AzContext $currentAzContext 
        }
    }

    try {
        Write-host "`n  [+] Running the scan with user: "$currentAzContext.Account
        $tenantList = Get-AzTenant
        Write-Host "`nAvailable Tenant ID/s:`n"
        Write-Host "  "($tenantList.Id | Format-Table | Out-String)
        
        if ($ScanSubscriptionId) {

            $subscriptionList = Get-AzSubscription -subscriptionId $ScanSubscriptionId

        }
        else {
            $subscriptionList = Get-AzSubscription | select Name, Id, TenantId 
        }

        if ($subscriptionList) {
            Write-Host "Available Subscription\s:"
            Write-Host ($subscriptionList | Format-Table | Out-String) -NoNewline
        }
    }
    catch {
        Write-Host "Encountered an error - check again the inserted Azure Credentials" -BackgroundColor red
        Write-Host "There was a problem when trying to access the target Azure Tenant\Subscription" -BackgroundColor Red
        Write-Host "Please try again.." 
        Write-Host "You can also try different Azure user credentials or test the scan on a different environment" 
        Return
    }      

    $AzContextAutosave = (Get-AzContextAutosaveSetting).CacheDirectory
    if ($AzContextAutosave -eq "None") {
        Enable-AzContextAutosave
    }  

    # Scan all the available subscription\s
    $subscriptionList | foreach {
        Write-Host "`n  [+] Scanning Subscription Name: "$($_.Name)", ID: $($_.Id)"
        Set-AzContext -SubscriptionId $_.id > $null
        $paramSplat = @{}

        $paramSplat.add('subscriptionId', $_.id)

    
        
        Run-SubscriptionScan @paramSplat
    }
    
    


}






























