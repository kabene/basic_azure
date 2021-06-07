#this script creates a basic Azure network, 1 domain controller, 1 client and 2 application servers for testing

#log in & get the subscription deets (sometimes its fastest to run this in the cloud shell)
#Subscription Info
$SubscriptionName = 'MS_CA_SimoneBennett'
$Subscription = (Get-AzSubscription -SubscriptionName $SubscriptionName)
$Location = 'australiaeast'

#Resource Group
$RgName = 'rg-core-infra'

#Select a subscription to work with
Connect-AzAccount
Select-AzSubscription -Subscription $SubscriptionName
Set-AzContext -Subscription $Subscription.id





#Generic Server Settings
$LicenceType="Windows_Server"
$IPAllocationMethod="Dynamic"
$VMSize="Standard_A1"
$PublisherName="MicrosoftWindowsServer"
$Offer="WindowsServer"
$SKUs="2019-Datacenter"
$WindowsVersion="Latest"
$DiskAccountType="Standard_LRS"
$DiagnosticStorageName="labdiagdata2019"
$cred=Get-Credential -Message "Type the name and password of the local administrator account."


#Create & Configure a Domain Controller
$VM1_Name="DC01"
$VMNAME1pip="DC01-PIP"
$VMNAME1nic="DC01-NIC"
$VM1_DataDiskName="DC01-DataDisk1"
$VM1_OsDiskName="DC01_OSDisk"
$VM1locName="Australiasoutheast"


$VMNAME1pip=New-AzureRMPublicIpAddress -Name $VMNAME1pip -ResourceGroupName $rgName -Location $VM1locName -AllocationMethod $IPAllocationMethod
$VMNAME1nic=New-AzureRMNetworkInterface -Name $VMNAME1nic -ResourceGroupName $rgName -Location $VM1locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $VMNAME1pip.Id
$vm=New-AzureRMVMConfig -VMName $VM1_Name -VMSize $VMSize -LicenseType $LicenceType
$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $VM1_Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $Offer -Skus $SKUs -Version $WindowsVersion
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $VMNAME1nic.Id
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $VM1_OsDiskName -DiskSizeInGB 128 -CreateOption fromImage
$diskConfig=New-AzureRmDiskConfig -AccountType $DiskAccountType -Location $VM1locName -CreateOption Empty -DiskSizeGB 20
$dataDisk1=New-AzureRmDisk -DiskName $VM1_DataDiskName -Disk $diskConfig -ResourceGroupName $rgName
$vm=Add-AzureRmVMDataDisk -VM $vm -Name $VM1_DataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
New-AzureRMVM -ResourceGroupName $rgName -Location $VM1locName -VM $vm
Set-AzureRmVMBootDiagnostics -VM $VM -Enable -ResourceGroupName $rgname -StorageAccountName $DiagnosticStorageName
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm

#add an extra disk to the DC01 machine
Get-Disk | Where PartitionStyle -eq "RAW" | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemDemoel "Data"

#create an app server
$VM1_Name="APP01"
$VMNAME1pip="APP01-PIP"
$VMNAME1nic="APP01-NIC"
$VM1_OsDiskName="APP01_OSDisk"
$VM1locName="Australiasoutheast"

$VMNAME1pip=New-AzureRMPublicIpAddress -Name $VMNAME1pip -ResourceGroupName $rgName -Location $VM1locName -AllocationMethod $IPAllocationMethod
$VMNAME1nic=New-AzureRMNetworkInterface -Name $VMNAME1nic -ResourceGroupName $rgName -Location $VM1locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $VMNAME1pip.Id
$vm=New-AzureRMVMConfig -VMName $VM1_Name -VMSize $VMSize -LicenseType $LicenceType
$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $VM1_Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $Offer -Skus $SKUs -Version $WindowsVersion
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $VMNAME1nic.Id
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $VM1_OsDiskName -DiskSizeInGB 128 -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $rgName -Location $VM1locName -VM $vm
Set-AzureRmVMBootDiagnostics -VM $VM -Enable -ResourceGroupName $rgname -StorageAccountName $DiagnosticStorageName
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm


#create a second app server
$VM1_Name="APP02"
$VMNAME1pip="APP02-PIP"
$VMNAME1nic="APP02-NIC"
$VM1_OsDiskName="APP02_OSDisk"
$VM1locName="Australiasoutheast"

$VMNAME1pip=New-AzureRMPublicIpAddress -Name $VMNAME1pip -ResourceGroupName $rgName -Location $VM1locName -AllocationMethod $IPAllocationMethod
$VMNAME1nic=New-AzureRMNetworkInterface -Name $VMNAME1nic -ResourceGroupName $rgName -Location $VM1locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $VMNAME1pip.Id
$vm=New-AzureRMVMConfig -VMName $VM1_Name -VMSize $VMSize -LicenseType $LicenceType
$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $VM1_Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $Offer -Skus $SKUs -Version $WindowsVersion
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $VMNAME1nic.Id
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $VM1_OsDiskName -DiskSizeInGB 128 -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $rgName -Location $VM1locName -VM $vm
Set-AzureRmVMBootDiagnostics -VM $VM -Enable -ResourceGroupName $rgname -StorageAccountName $DiagnosticStorageName
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm

#create a client
$VM1_Name="CLN01"
$VMNAME1pip="CLN01-PIP"
$VMNAME1nic="CLN01-NIC"
$VM1_OsDiskName="CLN01_OSDisk"
$VM1locName="Australiasoutheast"

$VMNAME1pip=New-AzureRMPublicIpAddress -Name $VMNAME1pip -ResourceGroupName $rgName -Location $VM1locName -AllocationMethod $IPAllocationMethod
$VMNAME1nic=New-AzureRMNetworkInterface -Name $VMNAME1nic -ResourceGroupName $rgName -Location $VM1locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $VMNAME1pip.Id
$vm=New-AzureRMVMConfig -VMName $VM1_Name -VMSize $VMSize -LicenseType $LicenceType
$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $VM1_Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $Offer -Skus $SKUs -Version $WindowsVersion
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $VMNAME1nic.Id
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $VM1_OsDiskName -DiskSizeInGB 128 -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $rgName -Location $VM1locName -VM $vm
Set-AzureRmVMBootDiagnostics -VM $VM -Enable -ResourceGroupName $rgname -StorageAccountName $DiagnosticStorageName
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm

#create an availability set
Install-Module AzureRm.AvailabilitySetManagement

$ASName="DemoApp_AvailabilitySet"
New-AzureRmAvailabilitySet -Location $locName -Name $ASname -ResourceGroupName $rgName -Sku aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 
Add-AzureRmAvSetVmToAvailabilitySet -ResourceGroupName $rgName -VMName "app01" -OsType windows -AvailabilitySet $asname
Add-AzureRmAvSetVmToAvailabilitySet -ResourceGroupName $rgName -VMName "app02" -OsType windows -AvailabilitySet $asname
get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $asname |select Name,Location,VirtualMachine* |fl





Write-Host -ForegroundColor Green "log in locally as corp\AdminUser1 to configure AD and App Servers"
Start-Sleep 60

#Log in & Install AD
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    Install-ADDSForest -DomainName corp.contoso.com -DatabasePath "F:\NTDS" -SysvolPath "F:\SYSVOL" -LogPath "F:\Logs"
        function Disable-ieESC {
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        Stop-Process -Name Explorer
        Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
    }
    Disable-ieESC
    Restart-Computer -Confirm

    #log in as a domain admin, create an admin user
    New-ADUser -SamAccountName User1 -AccountPassword (read-host "Set user password" -assecurestring) -name "AdminUser1" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false
    Add-ADPrincipalGroupMembership -Identity "CN=AdminUser1,CN=Users,DC=corp,DC=contoso,DC=com" -MemberOf "CN=Enterprise Admins,CN=Users,DC=corp,DC=contoso,DC=com","CN=Domain Admins,CN=Users,DC=corp,DC=contoso,DC=com","CN=Schema Admins,CN=Users,DC=corp,DC=contoso,DC=com"
    Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -enabled "True"

#create fake AD users
    #The file that contains the user information was created using [Spawner Data Generator http://spawner.sourceforge.net].
    #The column definition used is saved in the file 'SpawnerTableDefinition.txt'.

    #To add a new column to the output file containing the user name again (Name -> SamAccountName) the following PowerShell command line was used:
    #	Get-Content .\datagen.txt | ForEach-Object { $_ + ',' + ($_ -split ',')[0] } | Out-File .\datagen2.txt

    #The company names were taken from: http://www.click2inc.com/sample_names.htm and the the job titles were taken from
    #http://quest.arc.nasa.gov/people/titles.html. The following PowerShell command were used to add quotes and remove comma
    #	((Get-Content .\Companies.txt) | ForEach-Object { "`"$_`"" } | ForEach-Object { $_ -replace ",","" }) -join "|" | clip
    #	((Get-Content .\JobTitles.txt) | ForEach-Object { "`"$_`"" } | ForEach-Object { $_ -replace ",","" }) -join "|" | clip

    if (-not(Test-Path -Path $PSScriptRoot\DemoUsers.txt))
    {
    Write-Error 'The input file 'DemoUsers.txt' is missing.'
    return
}
    if ((Get-ADOrganizationalUnit -Filter "Name -eq 'Demo Accounts'"))
    {
    Write-Error "The OU 'Demo Accounts' does already exist"
    return
}

    $start = Get-Date

    #create a test OU in the current domain. We store the newly created OU...
    $ou = New-ADOrganizationalUnit -Name 'Demo Accounts' -ProtectedFromAccidentalDeletion $false -PassThru
    Write-Host "OU '$ou' created"
    #to be able to create a new group right in there
    $group = New-ADGroup -Name AllTestUsers -Path $ou -GroupScope Global -PassThru
    Write-Host "Group '$group' created"

    # import the TestUsers.txt file and pipe the imported data to New-ADUser.
    #The cmdlet New-ADUSer creates the users in test OU (OU=Test,<DomainNamingContext>).
    Write-Host 'Importing users from CSV file...' -NoNewline
    Import-Csv .\DemoUsers.txt `
	    -Header Name,GivenName,Surname,EmailAddress,OfficePhone,StreetAddress,PostalCode,City,Country,Title,Company,Department,Description,EmployeeID,SamAccountName | 
	    New-ADUser -Path $ou -ErrorAction SilentlyContinue
    Write-Host 'done'

    #Now the users should be in separate OUs, so we want to create one OU per country. In each OU is a group with the same name that all users of the OU are member of
    #AD uses ISO 3166 two-character country/region codes. We create a hash table that contains the two-character country code as key and the full name as value.
    #We read all test users and get the unique coutries. The RegionInfo class is use to convert the two-character coutry code into the full name
    Write-Host 'Getting countries of all newly added accounts...' -NoNewline
    $countries = @{}
    Get-ADUser -Filter "Description -eq 'Testing'" -Properties Country | 
	    Sort-Object -Property Country -Unique | 
	    ForEach-Object { 
		$region = New-Object System.Globalization.RegionInfo($_.Country)
		$countries.Add($region.Name, $region.EnglishName.Replace('.',''))
	}
    Write-Host "done, identified '$($countries.Count)' countries"
    Write-Host

    #We now take the countries' full name and create the OUs and groups.
    Write-Host 'Creating OUs and groups for countries and moving users...'
    foreach ($country in $countries.GetEnumerator())
    { 
    Write-Host "Working on country '$($country.Value)'..." -NoNewline
	$countryOu = New-ADOrganizationalUnit -Name $country.Value -Path $ou -ProtectedFromAccidentalDeletion $false -PassThru
    Write-Host 'OU, ' -NoNewline
	$group = New-ADGroup -Name $country.Value -Path $countryOu -GroupScope Global -PassThru    
	Add-ADGroupMember -Identity AllTestUsers -Members $group
    Write-Host 'Group, ' -NoNewline

    #Then we move the user to the respective OUs and add them to the corresponding group
    $countryUsers = Get-ADUser -Filter "Description -eq 'Testing' -and Country -eq '$($country.Key)'" -Properties Country
    $managers = @()
    1..4 | ForEach-Object { $managers += $countryUsers | Get-Random }

    $countryUsers | ForEach-Object { $_ | Set-ADUser -Manager ($managers | Get-Random) }
    Write-Host 'Managers, ' -NoNewline

    Add-ADGroupMember -Identity $country.Value -Members $countryUsers
    $countryUsers | Move-ADObject -TargetPath $countryOu
    Write-Host 'Users moved'

    #reset user pw's
    $SecPaswd= ConvertTo-SecureString –String ‘Summer2014’ –AsPlainText –Force
    get-aduser -filter 'Name -like "a*"'|Set-ADAccountPassword -Reset -NewPassword $SecPaswd
    get-aduser -filter 'Name -like "a*"'|Unlock-ADAccount
    get-aduser -filter 'Name -like "a*"'|Set-ADUser –ChangePasswordAtLogon $false -PasswordNeverExpires $true -enabled $true
}

    $end = Get-Date
    Write-Host
    Write-Host "User Creation Script finished in $($end - $start)"

    
    #Join the app server to the domain (corp\user1)

    Write-Host -ForegroundColor Green "Log in to configure the server"

    test-connection DC01.corp.contoso.com
    Add-Computer -DomainName corp.contoso.com
    Restart-Computer -Confirm

    function Disable-ieESC {
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        Stop-Process -Name Explorer
        Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
    }
    Disable-ieESC

    #install and configure PKI on the DC
    New-Item -ItemType directory -Path F:\PKI
    New-SmbShare -Name PKI -Path  F:\PKI -FullAccess "corp\Cert Publishers","corp\domain admins" -ReadAccess "everyone"  -Verbose 
    Get-FileShare -Name pki |Get-SmbShareAccess

    $acl = Get-Acl "\\DC01\PKI"
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("corp\Cert Publishers","Modify","Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl "\\DC01\PKI"

    Import-Module dnsserver
    Add-DnsServerClientSubnet -Name $SubnetName -IPv4Subnet $SubnetAddressPrefix
    Add-DnsServerResourceRecordA -Name certsrv -IPv4Address 10.0.0.4 -ComputerName DC01 -ZoneName corp.contoso.com
    ping certsrv

    Install-WindowsFeature AD-Certificate 
    Install-AdcsCertificationAuthority -CACommonName "Contoso Root CA" -CAType EnterpriseRootCa -HashAlgorithmName SHA256 -KeyLength 2048 -ValidityPeriod Years -ValidityPeriodUnits 100
    Install-WindowsFeature ADCS-Web-Enrollment
    Install-AdcsWebEnrollment
    #on the DC the certserver is availble at http://localhost/certsrv/certrqxt.asp
  
    
    #log in and configure the app servers (corp\user1)
    test-connection DC01.corp.contoso.com
    Add-Computer -DomainName corp.contoso.com
    function Disable-ieESC {
        $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        Stop-Process -Name Explorer
        Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
    }
    Disable-ieESC
    Restart-Computer -Confirm