#Subscription Info
<<<<<<< HEAD
$SubscriptionName = 'subscriptionName'
=======
$SubscriptionName = 'Subscription_Name'
>>>>>>> cf3d5a09e1a23ae05860beb161132917b053ccbc
$Location = 'australiasoutheast'

#Resource Group
$RgName = 'rg-core-infra'
$ContainerRgName = 'rg-demo-containers'

#Key Vault
$VaultName= ("CoreKeyVault-" + (Get-Random -Maximum 100))
<<<<<<< HEAD
$VaultUser = 'sibennett@microsoft.com'
=======
$VaultUser = 'email@outlook.com'
>>>>>>> cf3d5a09e1a23ae05860beb161132917b053ccbc

#Automation Account
$AutomationAccountName = 'CoreInfraAutomationAC'
$DisplayNameofAADApplication = 'CoreInfraGeneric'
$CertPwdSecureString = Read-Host "Enter a Password for the Run As Account Certificate" -AsSecureString

#Log Analytics Workspace
$WorkspaceName = "log-analytics-core-infra" + (Get-Random -Maximum 99999) # workspace names need to be unique in resource group
$WorkspaceTemplateFile = 'c:\temp\CreateWorkspace.json'
$WorkspaceDiagnosticTemplateFile = 'c:\temp\CreateDiagnosticSetting.json'

#Action Group
$AgReceiverName = 'ag-core-infra-email-reciever'
$AgName = 'ag-core-infra-alerts'
$AgShortName = 'core-alerts'
$ActionGroupEmailAddress = 'email@outlook.com'

#Azure Consumption Budget
$BudgetName = 'budgetcoreinfra'
<<<<<<< HEAD
$BudgetContact = "name@outlook.com", "name@microsoft.com"
=======
$BudgetContact = "email@outlook.com", "email@email.com"
>>>>>>> cf3d5a09e1a23ae05860beb161132917b053ccbc
$BudgetAmount = '50'

#Networking
$VnetName = 'vnet-core-infra'
$BastionSubnetName = 'AzureBastionSubnet'

#Container Group
$ContainerGrpName = 'web01'

#Azure Firewall
$FirewallName = 'demo-firewall'

#Define Virtual Machines
#Ref https://www.jorgebernhardt.com/create-multiple-identical-vms-at-once-with-azure-powershell/
#Get-AzComputeResourceSku | where {$_.Locations -icontains "$location"}
$computerName = @("Pet-VM-01","Pet-VM-02","Pet-VM-03","Pet-VM-03")
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


#Create a new Key Vault and grant acess to your user
#https://www.jorgebernhardt.com/how-to-create-an-azure-key-vault/
New-AzKeyVault -VaultName $VaultName -ResourceGroupName $RgName -Location $location -EnabledForDeployment -EnabledForTemplateDeployment -EnabledForDiskEncryption -Sku Standard -Tag @{Department="CoreInfra"} -verbose
Set-AzKeyVaultAccessPolicy -VaultName $VaultName -UserPrincipalName $VaultUser -PermissionsToSecrets get,set,delete

#Create a Log Analyitcs Workspace
New-AzOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -Sku pergb2018 -ResourceGroupName $RgName

#Create an Azure Automation account
$AZSubscription = Get-AzSubscription -SubscriptionName $SubscriptionName
Set-AzContext -Subscription $AzSubscription.id
New-AzAutomationAccount -Name $AutomationAccountName -Location $Location -ResourceGroupName $RgName -Tag @{Department="CoreInfra"} -verbose

#Create a RunAs Account - Has stopped working for me in some subs, need to troubleshoot
#Invoke-WebRequest https://raw.githubusercontent.com/azureautomation/runbooks/master/Utility/AzRunAs/Create-RunAsAccount.ps1 -outfile Create-RunAsAccount.ps1
#.\Create-RunAsAccount.ps1 -ResourceGroup $RgName -AutomationAccountName $AutomationAccountName -SubscriptionId $AZSubscription.Id -ApplicationDisplayName $DisplayNameofAADApplication  -SelfSignedCertPlainPassword $CertPwdSecureString -CreateClassicRunAsAccount $false

#Create an action group email receiver and corresponding action group
$email1 = New-AzActionGroupReceiver -EmailAddress $ActionGroupEmailAddress -Name $AgReceiverName -UseCommonAlertSchema
$ActionGroupId = (Set-AzActionGroup -ResourceGroupName $RgName -Name $AgName -ShortName $AgShortName -Receiver $email1).Id

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


#Create an NSG and subnets with basic rules
$rdpRule = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
   -SourceAddressPrefix * -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 3389 
    
$CoreNetworkSecurityGroup = New-AzNetworkSecurityGroup -ResourceGroupName $RgName `
  -Location $Location -Name "NSG-Core-Infra" -SecurityRules $rdpRule

$natgatewaypip = New-AzPublicIpAddress -Name "natgatewaypip" -ResourceGroupName $RgName `
   -Location $Location -Sku "Standard" -IdleTimeoutInMinutes 4 -AllocationMethod "static"

$bastionpip = New-AzPublicIpAddress -Name "bastionpip" -ResourceGroupName $RgName `
   -Location $Location -Sku "Standard" -AllocationMethod "static"

$natgateway = New-AzNatGateway -ResourceGroupName $RgName -Name "Nat_Gateway" `
   -IdleTimeoutInMinutes 4 -Sku "Standard" -Location $Location -PublicIpAddress $natgatewaypip

$natGatewaySubnet = New-AzVirtualNetworkSubnetConfig -Name NatGatewaySubnet `
   -AddressPrefix "10.0.1.0/24" -InputObject $natGateway

$frontendSubnet = New-AzVirtualNetworkSubnetConfig -Name FrontendSubnet `
   -AddressPrefix "10.0.3.0/24" -NetworkSecurityGroup $CoreNetworkSecurityGroup

$bastionSubnet = New-AzVirtualNetworkSubnetConfig -Name $BastionSubnetName `
   -AddressPrefix "10.0.5.0/27"

$backendSubnet = New-AzVirtualNetworkSubnetConfig -Name BackendSubnet `
   -AddressPrefix "10.0.4.0/24" -NetworkSecurityGroup $CoreNetworkSecurityGroup

$firewallSubnet = New-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet `
   -AddressPrefix "10.0.2.0/26"

New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RgName `
    -location $Location -AddressPrefix "10.0.0.0/16" -Subnet $frontendSubnet,$backendSubnet,$natGatewaySubnet,$bastionSubnet,$firewallSubnet

$VirtualNetwork = Get-AzVirtualNetwork -Name $VnetName

#Comment demo resource creation sections out to suit your needs
#Create a Basion Host
New-AzBastion -ResourceGroupName $RgName -Name $bastionName -PublicIpAddress $bastionpip -VirtualNetwork $VirtualNetwork

#Create some demo containers
New-AzContainerGroup -ResourceGroupName $ContainerRgName -Name $ContainerGrpName -Image nginx -OsType Linux -IpAddressType Public -Port @(8000)

#Create some pet servers
#Make sure the SKU you have specified is available in your subscrition
#Virtual Network Details
$nicName = "NIC-"

 for($i = 0; $i -le $ComputerName.count -1; $i++)  
{
 
 $NIC = New-AzNetworkInterface -Name ($NICName+$ComputerName[$i]) `
                               -ResourceGroupName $RgName `
                               -Location $Location `
                               -SubnetId $VirtualNetwork.Subnets[1].Id
 
#Virtual Machines
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


#Create an Azure Firewall & A Default Route to send all VM Traffic through the FW
#Get a Public IP for the firewall
$FWpip = New-AzPublicIpAddress -Name "fw-pip" -ResourceGroupName $rgName `
  -Location $Location -AllocationMethod Static -Sku Standard
$Azfw = New-AzFirewall -Name $FirewallName -ResourceGroupName $rgName -Location $Location -VirtualNetwork $VirtualNetwork -PublicIpAddress $FWpip

#Save the firewall private IP address for future use
$AzfwPrivateIP = $Azfw.IpConfigurations.privateipaddress
$AzfwPrivateIP

#Create a default route
$routeTableDG = New-AzRouteTable -Name Firewall-rt-table -ResourceGroupName $rgName -location $location -DisableBgpRoutePropagation

#Create a route table
 Add-AzRouteConfig -Name "DG-Route" -RouteTable $routeTableDG -AddressPrefix 0.0.0.0/0 -NextHopType "VirtualAppliance" -NextHopIpAddress $AzfwPrivateIP `
 | Set-AzRouteTable

#Associate the route table to the backend subnet
Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $VirtualNetwork -Name $backendSubnet.Name  -AddressPrefix 10.0.4.0/24 -RouteTable $routeTableDG `
   | Set-AzVirtualNetwork

#Resource Group Tags
#Apply Tags to the Resource Group
Set-AzResourceGroup -Name $rgName -Tag @{Name="$rgName";AutoShutdownSchedule="8PM -> 12AM, 2AM -> 7AM";"Environment Type"="Demo"}

#Apply the RG tags to all Resources in the RG
$tagsToApply=(Get-AzResourceGroup -Name $rgName).tags
get-AzResource -ResourceGroupName $rgName | foreach {
	Set-AzResource -ResourceId $_.resourceid -Tag $tagsToApply -Force
}

