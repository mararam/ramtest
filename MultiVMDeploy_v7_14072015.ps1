# Declaration of variables 
param(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$VCenterIPAddress,
    [Parameter(Mandatory=$true,Position=2)]
    [string]$VCenterUsername,
    [Parameter(Mandatory=$true,Position=3)]
    [string]$VCenterPassword,
    [Parameter(Mandatory=$true,Position=4)]
    [String]$VMInfo,
    [Parameter(Mandatory=$true,Position=5)]
    [string]$TgESXHostIPAddress,
    [Parameter(Mandatory=$true,Position=6)]
    [string]$DataStoreName,     
    [Parameter(Mandatory=$false,Position=7)]
    [string]$IpAddress,
    [Parameter(Mandatory=$false,Position=8)]
    [string]$SubnetMask,
    [Parameter(Mandatory=$false,Position=9)]
    [string]$DefaultGateway,
    [Parameter(Mandatory=$false,Position=10)]
    [string]$dns,
    [Parameter(Mandatory=$False,Position=11)]
    [string]$LogFileDir = "c:\TestBinRoot"	
)

# Initiating Log 

$LogPath = $LogFileDir + "\CreateSourceVM-" + [DateTime]::Now.GetDateTimeFormats()[105].ToString().Replace(":", "-") + ".log"

function logger ([string]$message)
{
  write-output [$([DateTime]::Now)] $message | out-file $LogPath -Append
}

try
{
	# Adding snap in to read VMWare PowerClI Commands through power shell

	Add-PSSnapin "VMware.VimAutomation.Core" | Out-Null

	# Capturing inputs provided by the user

	logger " You had provided the following inputs:"
	logger "========================================"
	logger " USAGE: IP Address should be specified in format _._._._ "
	logger " vCenter IPAddress: $VCenterIPAddress"
	logger " USAGE: Provide user-name which has access to login into the vCenter" 
	logger " vCenter UserName : $VCenterUsername"
	logger " USAGE: Provide correct authorized account password to login"
	logger " vCenter Password : $VCenterPassword"
	logger " VM COUNT = Provide no. of VM's to be deployed"
	logger " TEMPLATE NAME = Template name should be provided from the given list only"
	logger " VMPREFIX NAME = Provide unique VM Name which will be appended by VMNAME-01 as per the count"
	logger " OSTYPE: Should be W for Windows (or) L for Linux (or) DW for Windows DHCP (or) DL for Linux DHCP and S to Skip the OS Customization" 
	logger " CUSTOMSPECNAME: Should be WINM for Windows and LINM for Linux for Static IP's and DWINS and DLIN for Windows and Linux DHCP"
	logger " USAGE >>[VM COUNT]:[TEMPLATE NAME]:[VMPREFIX NAME]:[OSTYPE]:[CUSTOMSPECNAME] : $VMInfo "
	logger " USAGE: Provide existing ESX IP Address which has enough Configuration such as CPU, RAM and Storage"
	logger " Target ESX Server IP: $TgESXHostIPAddress"
	logger " USAGE: Provide Unique data store name at the vCenter level"
	logger " DataStore Name: $DataStoreName"
	Logger " USAGE: Provide starting free IP Address as per the count to avoid duplicate generation"
	logger " IPAddress: $IpAddress"
	logger " USAGE: Provide correct subnet mask in format _._._._ "
	logger " SubNetMask: $SubnetMask"
	logger " USAGE: Provide correct gateway which is ping-able" 
	logger " Default Gateway:  $DefaultGateway"
	logger " USAGE: Provide existing DNS IP which is reachable"
	logger " DNS: $dns"
	logger "========================================"
	# Connecting to vCenter Server

	logger " ************* Please ignore the initial vCenter Connection Logs ********************** " 

	Connect-VIServer -Server $VCenterIPAddress -User $VCenterUsername -Password $VCenterPassword *>>$LogPath
	If ($defaultviservers.IsConnected -ne $NULL)
	{
		logger "INFO: Connection to  $VCenterIPAddress is successful" 
	}
		else
	{
		logger "ERROR: Connection to $VCenterIPAddress Failed..Check the Log" 
		exit 1 
	}

	logger " ***************************************************************************************** "

	# Spilling  the  inputs as per the requirement

	$Instance = $VMInfo.Split('/')
	foreach ($List in $Instance)
	{			
		$VMData = $List.Split(':')
		foreach( $Count in $List)
		{	
		# Temporary VMCount after spilling the inputs
		$nvmcount = $VMData[0]
		# Temporary template name after spilling the inputs
		$t_templatename = $VMData[1]
		# Temporary VMPrefixName after spilling the inputs
		$t_vmprefixname = $VMData[2]
		# Temporary OSTYPE after spilling the inputs
		$t_ostype = $VMData[3]
		# Temporary OSCustSpec after spilling the inputs
		$t_oscusspec = $VMData[4]
		
	Write-Host "Started Creating of the VMs " 
	logger "INFO: Started Creating of the VMs"
	$output = for($iteration=1; $iteration -le $nvmcount; $iteration++)
				
				{				
					logger "No. of VM's Count: $iteration"
					
					$TemplateName = $t_templatename
					logger "Provided Template Name: $TemplateName"
					
					$VMPrefixName = $t_vmprefixname
					logger "Provided VM/HostName Prefix Name: $VMPrefixName"
					
					$OSType = $t_ostype
					logger "OS Type : $OSType"
					
					$OSCustSpec = $t_oscusspec
					logger "OS CustomSpec Name: $OSCustSpec"														

					$VMName = $VMPrefixName + "-" + $iteration.ToString("00")
					logger "INFO: Started VM Creation - $VMName"

					# Checking for the existing VM and shutting down and deleting it if exists.
					Write-Host " Verifying the existing VM/HostName Info"
					logger "INFO: Verifying the existing VM/HostName Info"
					$state = Get-VM -Name $VMName						
					If( $state.PowerState -eq "PoweredOn" -OR $state.PowerState -eq "PoweredOff" )
					{	
						If( $state.PowerState -eq "PoweredOn" )	
						{
						logger "INFO: Deleting the existing VM's with the same prefix name"
						logger "INFO: Shutting down the VM(s)"
						Stop-VM -VM (Get-VM -Name $VMName) -confirm:$false *>>$LogPath
							if( $? -eq "True" )
								{
								logger " INFO: VM got shut-down successfully"
								} else 
								{
								logger " ERROR: VM did not shut-down successfully"
								exit 1
								}
						}					
						Remove-VM $VMName -DeleteFromDisk -confirm:$false *>>$LogPath
							if ( $? -eq "True" )
								{
								logger " INFO: VM got delete successfully"
								} else
								{
								logger " ERROR: VM did not delete successfully"
								exit 1
								}						
					} 					
					else
					{
						logger "INFO: VM/HostName Info does not exists"
					}									

					# Doing OS Customization based on the OS Type. 
				If ($OSType -eq "L")
				{
						Write-Host " You are deploying Linux Machine using static IP"
						Get-OSCustomizationSpec -name $OSCustSpec | Get-OSCustomizationNICMapping | Set-OSCustomizationNICMapping -IpMode UseStaticIP -IpAddress $IpAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway *>>$LogPath
							if ( $? -eq "True" )
							{
							logger "INFO: OS Customization has done successfully"
							}
						else
							{
							logger "ERROR: OS Customization has not done successfully"
							exit 1
							}
				} 
				else  
				{
					If ($OSType -eq "W") 
					{
						Write-Host " You are deploying Windows Machine using static IP"
						Get-OSCustomizationSpec -name $OSCustSpec | Get-OSCustomizationNICMapping | Set-OSCustomizationNICMapping -IpMode UseStaticIP -IpAddress $IpAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway -dns $dns *>>$LogPath
							if ( $? -eq "True" )
							{
							logger "INFO: OS Customization has done successfully"
							}
						else
							{
							logger "ERROR: OS Customization has not done successfully"
							exit 1
							}
				}  
				else  
				{
					If($OSTYPE -eq "DW")
					{
							Write-Host "You are deploying windows machine using DHCP"
							Get-OSCustomizationSpec -name $OSCustSpec | Get-OSCustomizationNICMapping | Set-OSCustomizationNICMapping -IpMode UseDhcp *>>$LogPath
							if ( $? -eq "True")
							{
							logger "INFO: OS Customization has done successfully"
							}
							else
							{
							logger " ERROR: OS Customization has not done successfully"
							}
						}
						else
						{
							If($OSTYPE -eq "DL")
							{
							Write-Host "You are deploying Linux machine using DHCP"
							Get-OSCustomizationSpec -name $OSCustSpec | Get-OSCustomizationNICMapping | Set-OSCustomizationNICMapping -IpMode UseDhcp *>>$LogPath
								if ( $? -eq "True")
								{
								logger "INFO: OS Customization has done successfully"
								}
							else
								{
								logger " ERROR: OS Customization has not done successfully"
								}
						}
						else
						{
							If ($OSType -eq "S") 
								{
								Write-Host " You are deploying machine without OS Customization"											
								}	
							else  
								{
								Write-Host "Provide the Correct Option W or L or DW or DL or S" 
								logger "ERROR: Provide the Correct Option W or L or DW or DL or S"
								exit 1						
								}	
							}
						}
					}					
				}		
					# Creating a new VM based on the user inputs.
					New-VM -name $VMName -VMHost $TgESXHostIPAddress -Template $TemplateName -DataStore $DataStoreName -OSCustomizationSpec $OSCustSpec *>>$LogPath
					if ( $? -eq "True" )
						{
						logger "INFO: VM created successfully"
						}
					else
						{
						logger "ERROR: VM didn't created successfully"
						exit 1
						}

					# This will increment the provided starting IP Address as per the count specified
					#$NextIP = $IpAddress.Split(".")
					#$NextIP[3] = [INT]$NextIP[3]+1
					#$IpAddress = $NextIP -Join"."

					sleep 5;
					
					# Powering on the VM(s)
					Write-Host "Powering on the VM's"
					Start-VM $VMName
					if ( $? -eq "True" )
						{
						logger "INFO: VM powered on successfully"
                         # sleeping for 7 mins for customization and IP allocation
						logger "INFO: Sleeping for 7 mins for OS Customization"
						sleep 420;
						}
					else
						{
						logger "ERROR: VM didn't powered on successfully"
						exit 1
						}
				}
		}
	}
	logger $output
	#Disconnecting the VM after the doing all the operations.
	Write-Host "Disconnecting the vCenter Server"
	logger "Disconnecting the vCenter Server"
	Disconnect-VIServer -server  $global:DefaultVIServers -force -confirm:$false -ErrorAction SilentlyContinue
}
catch
{
		logger "Exception caught" + $_.Exception.Message
		exit 1
}