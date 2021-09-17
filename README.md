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

Make sure you configure usage and budget alerts so you don't use up all of your credits!

For more info see: https://simone-au.medium.com/getting-started-with-azure-for-free-431d206c26a6

To clean up everything that has been created: Remove-AzResourceGroup -Name $rgname