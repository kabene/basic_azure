<#
Azure Lighthouse Demo Base Setup
* NB: You'll need at least two azure subscriptions; a managed service provider (MSP) and a customer
* For this setup I signed up for 2 free (as in beer) Visual Studio Subscriptions which you can get here https://azure.microsoft.com/en-us/free/?ref=VisualStudio
* I populated them with some core infrastructure using these scripts


This super basic script uses the pre-defined access delegation templates that are available here https://github.com/Azure/Azure-Lighthouse-samples/ 
And grants a demo Managed Service Provider (MSP) access to the entire Customer Subscription as opposed to a single resource group

A realy good overview of Lighthouse is available here https://techcommunity.microsoft.com/t5/itops-talk-blog/ops118-deep-dive-on-onboarding-customers-into-lighthouse/ba-p/2109488
#>

#Where To Save the Template Files
$PathToTemplateFiles = 'C:\Temp'

#Customer Subscription Info
$CustomerSubscriptionId = "4dac708b-9831-4de2-95c7-29908e68c285"
$CustomerSubscriptionName = "Visual Studio Enterprise"

#Managed Service Provider Subscription Info
$SubscriptionName = "Free Trial"
$Location = "australiasoutheast"

$AdminGroup = "Customer1Admins" #Azure AD admin group in the  in the Managed Service Provider(MSP) tenant
$AdminGroupMembers = ""
$MSPOfferName = 'Customer1 Lighthouse MSP Access'

#Need to create a group with fake users and add them to the admin group
#$AdminGroupMembers = (Get-AzureADUser -Filter "userPrincipalName eq '*simone*'")
#Maybe create and add a SP 
#Serice Principal = $AdminApplication CoreInfraGeneric
#Retrieve the objectId for an SPN
#$SPN = (Get-AzADApplication -DisplayName $AdminApplication | Get-AzADServicePrincipal)


#Log in first with Connect-AzAccount since we're not using Cloud Shell
Import-Module Az -Verbose
Connect-AzAccount
$AZSubscription = Get-AzSubscription -SubscriptionName $SubscriptionName
$Context = Get-AzContext

#Confirm the MSP subscription is selected before continuing
write-host ("Managed Service Provider (MSP) Permissions will be granted to the following subscription: " + $Context.Name) -foregroundcolor Green
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 

#Connect to the MSP Subscription
Get-AzSubscription -SubscriptionName $SubscriptionName| Set-AzContext -Force -debug
Write-Host ("Log into the MSP Subscription") -foregroundcolor Green
Connect-AzureAD -TenantId $AzSubscription.TenantId

#Register the Microsoft.ManagedServices Provider 
Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedServices

<#
Check for or Create the Lighthouse Admin Group for Customer1 in the MSP Tenant
* In order to add Lighthouse permissions for an Azure AD group, the Group type must be set to Security
* Ref https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer
#>

$GroupExists = Get-AzureAdGroup -All $True | Where-Object {$_.DisplayName -like $AdminGroup}
if ($GroupExists)
{
Write-Host "Group $($GroupName) has already been created.
" -foregroundcolor Green
}
else
{
New-AzureADGroup -DisplayName $AdminGroup -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet" -Description "Used to enable lighthouse access to customer resources"
Write-Host "Group $($GroupName) did not exsist it has now been been created.
" -foregroundcolor Green
}


#Retrieve the objectId for an MSP Azure AD group
$AdminGroupId = (Get-AzADGroup -DisplayName $AdminGroup).id

<#
Retrieve role definition IDs that will be assigned in the customer environment
* Only can use built in roles
* The roles “Owner” and “User Access Administrator” cannot be used 
* (Except in the last line of the JSON template where they're used to allow the MSP to grant limited access to Service Principals in the Customer tenant)
* Ref https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer
#>
$SecurityAdminRole = (Get-AzRoleDefinition -Name 'Security Admin')
$ReaderRole = (Get-AzRoleDefinition -Name 'Reader')
$UserAccessAdminRole = (Get-AzRoleDefinition -Name 'User Access Administrator')
$ContributorRole = (Get-AzRoleDefinition -Name 'Contributor')
$LogAnalyticsContributorRole = (Get-AzRoleDefinition -Name 'Log Analytics Contributor')


#Download the Lighthouse Delegated Resource Management Templates
New-Item -Path $PathToTemplateFiles -Name "Lighthouse" -ItemType "directory"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Azure/Azure-Lighthouse-samples/master/templates/delegated-resource-management/delegatedResourceManagement.json' -OutFile $PathToTemplateFiles\Lighthouse\delegatedResourceManagement.json -ErrorAction Stop -Verbose
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Azure/Azure-Lighthouse-samples/master/templates/delegated-resource-management/delegatedResourceManagement.parameters.json' -OutFile $PathToTemplateFiles\Lighthouse\delegatedResourceManagement.parameters.json -ErrorAction Stop -Verbose

<#
Update the Lighthouse Template Perameters.json file
Will grant the MSP AdminGroup Reader & Security Admin Rights in the Customer Subscription Once Applied
NB Each authorization in the template includes a principalId which refers to an Azure AD user, group, or service principal in the MSP tenant. 
In this demo principalId refers to the Customer1Admins Group
#>

(Get-Content -path $PathToTemplateFiles\Lighthouse\delegatedResourceManagement.parameters.json -Raw) | Foreach-Object {
    $_ -replace 'Relecloud Managed Services',$MSPOfferName `
       -replace '<insert managing tenant id>', $AzSubscription.TenantId `
       -replace 'ee8f6d35-15f2-4252-b1b8-591358e8a244', $AdminGroupId `
       -replace 'PIM_Group', $AdminGroup `
       -replace 'acdd72a7-3385-48ef-bd42-f606fba81ae7', $SecurityAdminRole.id `
       -replace '91c1777a-f3dc-4fae-b103-61d183457e46', $ReaderRole.id `
       -replace '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9', $UserAccessAdminRole.id `
       -replace 'b24988ac-6180-42a0-ab88-20f7382dd24c', $ContributorRole.id `
       -replace '92aaf0da-9dab-42b6-94a3-d43ce8d16293', $LogAnalyticsContributorRole.id
    } | Set-Content -Path $pathtotemplatefile\lighthouse\delegatedResourceManagement.parameters.json


Write-Host "Switch to the Customer Subscription $CustomerSubscriptionName $CustomerSubscriptionId" -foregroundcolor Green

#Log in first with Connect-AzAccount since we're not using Cloud Shell
Connect-AzAccount
$CustomerContext = Get-AzContext

#Confirm the correct subscription is selected before continuing
Write-Host ("Templates will be Deployed and Permissions will be granted to the MSP in the following subscription:  " + $CustomerContext.Name) -foregroundcolor Green
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 

#Deploy Azure Resource Manager template using template and parameter file locally
New-AzSubscriptionDeployment -Name DeployServiceProviderTemplate `
                 -Location $Location `
                 -TemplateFile $PathToTemplateFiles\Lighthouse\delegatedResourceManagement.json `
                 -TemplateParameterFile $PathToTemplateFiles\Lighthouse\delegatedResourceManagement.parameters.json `
                 -Verbose

#Confirm Successful Onboarding for Azure Lighthouse
Get-AzManagedServicesDefinition |fl
Get-AzManagedServicesAssignment |fl

Write-Host ("In about 15 minutes the MSP should be visible in the Customer Subscription") -foregroundcolor Green
Start-Process "https://portal.azure.com/#blade/Microsoft_Azure_CustomerHub/ServiceProvidersBladeV2/providers"