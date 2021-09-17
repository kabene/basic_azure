# Test Azure Subscription
Populates a test azure subscription with: 
 * rg-core-infra resource group for all core infrastructure 
 * rg-demo-containers resource group for demo containers

 * Some demo Linux container instances
 * A bastion host
 * An Automation Account, Self Signed Certificate & RunAs Account
 * A few Windows VM’s with associated NIC's and Disks
 * A KeyVault
 * An Azure Firewall, Firewall Route table and Default Route from the Backend Subnet
 * An action group, monthly budget and budget alert
 * Resource Group Tags for all deployed resources
 * Repo also includes an excel file that can be used to create a bunch of test or fake Azure AD users using the "Bulk Upload" feature in the portal. 


 * A simple Virtual Network with the 10.0.0.0/16 address space
   * A NatGatewaySubnet (10.00.1.24) and Network Gateway Public IP (PIP)
   * An AzureFirewallSubnet (10.0.0.2.26) and Firewall PIP
   * A FrontEndSubnet (10.0.0.3.0/24)
   * A BackEndSubnet (10.0.0.4.0/24)
   * An AzureBastionSubnet (10.0.0.5.0/27) and Bastion PIP


* Make sure you configure usage and budget alerts so you don't use up all of your credits!
* Repo also includes an excel file that can be used to create a bunch of test or fake Azure AD users using the "Bulk Upload" feature in the portal. 

For a step by step guide: https://simone-au.medium.com/deploy-some-test-azure-resources-azure-ad-users-db36c06b7dd4

To delete everything: Remove-AzResourceGroup -Name $rgname

Diagram as at September 2021
![image](https://user-images.githubusercontent.com/67363016/133755334-0ad18ece-4be8-454c-b85a-aa683d553721.png)
