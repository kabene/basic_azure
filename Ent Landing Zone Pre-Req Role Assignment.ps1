#Install the AZ Modules
#More info https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.8.0
#Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -Verbose
Import-Module Az.Accounts

#Subscription Info
$SubscriptionName = 'Free Trial'
$TenantId = '91735807-a566-4bb5-896e-252f7f46c736'


#Set the correct Az-AD Context
Clear-AzContext
Connect-AzAccount -Tenant $TenantId

#Select a subscription to work with
Select-AzSubscription -Subscription $SubscriptionName

#Get the object Id of  the current user

$token = Get-AzAccessToken -Resource "https://graph.microsoft.com/"
$headers = @{ Authorization = "Bearer $($token.Token)" }
$user = Invoke-RestMethod https://graph.microsoft.com/v1.0/me -Headers $headers

#Assign Owner  role to Tenant root scope ("/") as a User Access Administrator
New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.id

