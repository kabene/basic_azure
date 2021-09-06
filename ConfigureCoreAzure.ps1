#Subscription Info
$SubscriptionName = 'MS_CA_SimoneBennett'
$Location = 'australiasoutheast'

#Resource Group
$RgName = 'rg-core-infra'
$BastionRgName = 'rg-bastion'
$ContainerRgName = 'rg-demo-containers'

#Key Vault
$VaultName= ("CoreKeyVault-" + (Get-Random -Maximum 100))
$VaultUser = 'simone.bennett.demo@outlook.com'

#Automation Account
$AutomationAccountName = 'CoreInfraAutomationAC'
$DisplayNameofAADApplication = 'CoreInfraGeneric'
$CertPwdSecureString = Read-Host "Enter a Password for the Run As Account Certificate" -AsSecureString

#Log Analytics Workspace
$WsName = 'ws-core-infra'
$WsTemplateFile = 'c:\temp\CreateWorkspace.json'
$WsDiagnosticTemplateFile = 'c:\temp\CreateDiagnosticSetting.json'

#Action Group
$AgReceiverName = 'ag-core-infra-email-reciever'
$AgName = 'ag-core-infra-alerts'
$AgShortName = 'core-alerts'
$ActionGroupEmailAddress = 'email@outlook.com'

#Azure Consumption Budget
$BudgetName = 'budgetcoreinfra'
$BudgetContact = "simone.bennett.demo@outlook.com", "sibennett@microsoft.com"
$BudgetAmount = '50'

#Networking
$VnetName = 'vnet-core-infra'
$BastionVnetName = "BastionVnet"
$BastionSubnetName = "BastionSubnet"

#Container Group
$ContainerGrpName = 'web01'

#Define Virtual Machines
#Ref https://www.jorgebernhardt.com/create-multiple-identical-vms-at-once-with-azure-powershell/
#Get-AzComputeResourceSku | where {$_.Locations -icontains "$location"}
$computerName = @("Pet-VM-01","Pet-VM-02","Pet-VM-03","Pet-VM-04")
$bastionName = "Bastion-Host-O1"
$vmSize = "Standard_B1s"
$publisherName = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$skus = "2016-Datacenter"
$PetCredential = Get-Credential -Message "Please enter a un/pw for the pet servers.Windows admin user name cannot be more than 20 characters long, be empty, end with a period(.), or contain special characters"

#Figure out the Budget Start and End Dates
$date = Get-Date
$year = $date.Year
$month = $date.Month
$date = $date.AddYears(1)
$endYear = $date.Year
$startDate = Get-Date -Year $year -Month $month -Day 1
$endDate = Get-Date -Year $endYear -Month $month -Day 1
$startDateStr = '{0:yyyy-MM-dd}' -f $startDate
$endDateStr = '{0:yyyy-MM-dd}' -f $endDate

$BudgetStart= ((Get-Date -Year $year -Month $month -Day 1).ToUniversalTime()).ToString("yyyy-MM-ddT00:00:00Z")
$BudgetEnd= ((Get-Date -Year $endYear -Month $month -Day 1).ToUniversalTime()).ToString("yyyy-MM-ddT00:00:00Z")


#Install the AZ Modules
#More info https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.8.0
#Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -Verbose
Import-Module Az.Accounts

#Connect to your Azure Account
Connect-AzAccount

#Select a subscription to work with
Select-AzSubscription -Subscription $SubscriptionName

#Create a new resource group for core infrastructure, demo containers & bastion host
New-AzResourceGroup -Name $RgName -Location $Location -Tag @{Department="CoreInfra"}
New-AzResourceGroup -Name $ContainerRgName -Location $Location -Tag @{Department="DemoContainers"}
New-AzResourceGroup -Name $BastionRgName -Location $Location -Tag @{Department="DemoBastion"}


#Create a new Key Vault and grant acess to your user
#https://www.jorgebernhardt.com/how-to-create-an-azure-key-vault/
New-AzKeyVault -VaultName $VaultName -ResourceGroupName $RgName -Location $location -EnabledForDeployment -EnabledForTemplateDeployment -EnabledForDiskEncryption -Sku Standard -Tag @{Department="CoreInfra"} -verbose
Set-AzKeyVaultAccessPolicy -VaultName $VaultName -UserPrincipalName $VaultUser -PermissionsToSecrets get,set,delete

#Create an Azure Automation and RunAs Account
$AZSubscription = Get-AzSubscription -SubscriptionName $SubscriptionName
Set-AzContext -Subscription $AzSubscription.id

New-AzAutomationAccount -Name $AutomationAccountName -Location $Location -ResourceGroupName $RgName -Tag @{Department="CoreInfra"} -verbose
Invoke-WebRequest https://raw.githubusercontent.com/azureautomation/runbooks/master/Utility/AzRunAs/Create-RunAsAccount.ps1 -outfile Create-RunAsAccount.ps1
.\Create-RunAsAccount.ps1 -ResourceGroup $RgName -AutomationAccountName $AutomationAccountName -SubscriptionId $AZSubscription.Id -ApplicationDisplayName $DisplayNameofAADApplication  -SelfSignedCertPlainPassword $CertPwdSecureString -CreateClassicRunAsAccount $false


#Create an action group email receiver and corresponding action group
$email1 = New-AzActionGroupReceiver -EmailAddress $ActionGroupEmailAddress -Name $AgReceiverName -UseCommonAlertSchema
$ActionGroupId = (Set-AzActionGroup -ResourceGroupName $RgName -Name $AgName -ShortName $AgShortName -Receiver $email1).Id

#Create an NSG and Subnet with basic rules
$rdpRule = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
   -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 3389 
    
$networkSecurityGroup = New-AzNetworkSecurityGroup -ResourceGroupName $RgName `
  -Location $Location -Name "NSG-FrontEnd" -SecurityRules $rdpRule

$natgatewaypip = New-AzPublicIpAddress -Name "natgatewaypip" -ResourceGroupName $RgName `
   -Location $Location -Sku "Standard" -IdleTimeoutInMinutes 4 -AllocationMethod "static"

$bastionpip = New-AzPublicIpAddress -Name "bastionpip" -ResourceGroupName $RgName `
   -Location $Location -Sku "Standard" -AllocationMethod "static"

$natgateway = New-AzNatGateway -ResourceGroupName $RgName -Name "Nat_Gateway" `
   -IdleTimeoutInMinutes 4 -Sku "Standard" -Location $Location -PublicIpAddress $natgatewaypip

$natGatewaySubnet = New-AzVirtualNetworkSubnetConfig -Name NatGatewaySubnet `
   -AddressPrefix "10.0.1.0/24" -InputObject $natGateway

$frontendSubnet = New-AzVirtualNetworkSubnetConfig -Name FrontendSubnet `
   -AddressPrefix "10.0.3.0/24" -NetworkSecurityGroup $NetworkSecurityGroup

$bastionSubnet = New-AzVirtualNetworkSubnetConfig -Name BastionSubnet `
   -AddressPrefix "10.0.2.0/24"

$backendSubnet = New-AzVirtualNetworkSubnetConfig -Name BackendSubnet `
   -AddressPrefix "10.0.4.0/24" -NetworkSecurityGroup $networkSecurityGroup

New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RgName `
    -location $Location -AddressPrefix "10.0.0.0/16" -Subnet $frontendSubnet,$backendSubnet,$natGatewaySubnet,$bastionSubnet


#Create some demo containers
New-AzContainerGroup -ResourceGroupName $ContainerRgName -Name $ContainerGrpName -Image nginx -OsType Linux -IpAddressType Public -Port @(8000)


#Create some pet servers
#Make sure the SKU you have specified is available in your subscrition

#Virtual Network 
$nicName = "NIC-"
$vnet = Get-AzVirtualNetwork -Name $VnetName `
                             -ResourceGroupName $RgName
 


 for($i = 0; $i -le $ComputerName.count -1; $i++)  
{
 
 $NIC = New-AzNetworkInterface -Name ($NICName+$ComputerName[$i]) `
                               -ResourceGroupName $RgName `
                               -Location $Location `
                               -SubnetId $Vnet.Subnets[0].Id
 
 $VirtualMachine = New-AzVMConfig -VMName $ComputerName[$i] `
                                  -VMSize $VMSize
 $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
                                           -Windows `
                                           -ComputerName $ComputerName[$i] `
                                           -Credential $PetCredential `
                                           -ProvisionVMAgent  `
                                           -EnableAutoUpdate
 
 $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine `
                                            -Id $NIC.Id
 $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
                                       -PublisherName $publisherName `
                                       -Offer $offer `
                                       -Skus $skus `
                                       -Version latest
 
 New-AzVM -ResourceGroupName $RgName `
          -Location $Location `
          -VM $VirtualMachine `
          -Verbose
}



#Create a monthly budget that sends an email and triggers an Action Group to send a second email 
#Make sure the StartDate for your monthly budget is set to the first day of the current month

#In May 2021 this had a bug and was not working. Check the GitHub issue for updates: https://github.com/Azure/azure-powershell/issues/11642
#Can be manually created in the portal

New-AzConsumptionBudget `
   -Name $BudgetName `
   -Amount $BudgetAmount `
   -Category "Cost" `
   -TimeGrain "Monthly" `
   -StartDate $BudgetStart `
   -EndDate $BudgetEnd `
   -ContactEmail $BudgetContact `
   -ContactGroup $ActionGroupId `
   -NotificationKey "70 % Usage" `
   -NotificationEnabled `
   -NotificationThreshold 90 `
   -Debug



#Resource Group Tags
#Apply Tags to the Resource Group
Set-AzResourceGroup -Name $rgName -Tag @{Name="$rgName";AutoShutdownSchedule="8PM -> 12AM, 2AM -> 7AM";"Environment Type"="Demo"}

#Apply the RG tags to all Resources in the RG
$tagsToApply=(Get-AzResourceGroup -Name $rgName).tags
get-AzResource -ResourceGroupName $rgName | foreach {
	Set-AzResource -ResourceId $_.resourceid -Tag $tagsToApply -Force

}

