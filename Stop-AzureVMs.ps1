<#

    .SYNOPSIS 
        Stops all the Azure VMs in a specific Azure Resource Group

    .DESCRIPTION
        This sample runbooks stops all of the virtual machines in the specified Azure Resource Group. 
        For more information about how this runbook authenticates to your Azure subscription, see the
        Microsoft documentation here: http://aka.ms/fxu3mn. 

        Note: If you do not uncomment the "Select-AzureSubscription" statement (on line 57) and insert
        the name of your Azure subscription, the runbook will use the default subscription.

    .PARAMETER ResourceGroupName
        Name of the Azure Resource Group containing the VMs to be started.

    .REQUIREMENTS 
        THis runbook requires the Azure Resource Manager PowerSHell module has been imported into 
        your Azure Automation instance.

        This runbook will only return VMs deployed using the new Azure IaaS features available in the
        Azure Preview Portal and Azure Resource Manager templates. For more information, see 
        http://azure.microsoft.com/en-us/documentation/videos/build-2015-introduction-and-what-s-new-in-azure-iaas/. 
    
    .NOTES
        AUTHOR: Hilton Pereira
        LASTEDIT: 9/27/2016
#>


    
	param(

  	[string]$ResourceGroupName

 	)
	
<#Get the credential with the above name from the Automation Asset store
    $Cred = Get-Credential 
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }
#>
    #Connect to your Azure Account
    $ResourceGroupName = "SqlClusterResource"
 <#  $Account = Login-AzureRmAccount -Credential $Cred
    if(!$Account) {
        Throw "Could not authenticate to Azure using the credential asset '${CredentialAssetName}'. Make sure the user name and password are correct."
    }
#>
        $VMs =Get-AzureRmVM -ResourceGroupName "$ResourceGroupName"
		
    #Get all the VMs you have in your Azure subscription
     $VMs = Get-AzureRmVM -ResourceGroupName "$ResourceGroupName"

    #Print out up to 10 of those VMs
     if(!$VMs) {
        Write-Output "No VMs were found in your subscription."

     } else {

		Foreach ($VM in $VMs) {
		Stop-AzureRmVM -ResourceGroupName "$ResourceGroupName" -Name $VM.Name -Force -ErrorAction SilentlyContinue
		}
     }
