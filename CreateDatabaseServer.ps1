workflow CreateDatabaseServer
{
	 $AzureConn = Get-AutomationConnection -Name "AzureManagement"
         		if ($AzureConn -eq $null)
    		{
        		throw "Could not retrieve 'AzureManagement' connection asset. Check that you created this first in the Automation service."
    		}
		
    		# Get the Azure management certificate that is used to connect to this subscription
    		$Certificate = Get-AutomationCertificate -Name $AzureConn.AutomationCertificateName
    		if ($Certificate -eq $null)
    		{
        		throw "Could not retrieve '$AzureConn.AutomationCertificateName' certificate asset. Check that you created this first in the Automation service."
    		}
	  		# Set the Azure subscription configuration
    		Set-AzureSubscription -SubscriptionName "AzureManagement" -SubscriptionId $AzureConn.SubscriptionID -Certificate $Certificate 
			Select-AzureSubscription -SubscriptionName "AzureManagement"
            $servercredential =Get-AutomationPSCredential -Name "DatabaseCredentials"
            $serverLogin=$servercredential.GetNetworkCredential().username
            $serverPassword=$servercredential.GetNetworkCredential().password 
            $server = New-AzureSqlDatabaseServer -AdministratorLogin $serverLogin -AdministratorLoginPassword $serverPassword -Location "West US"
            Get-AzureSqlDatabaseServer | Get-AzureSqlDatabaseServerFirewallRule
            $server | New-AzureSqlDatabaseServerFirewallRule -RuleName AllOpen -StartIPAddress 0.0.0.0 -EndIPAddress 255.255.255.255
            $ServerName=$server.ServerName
		    Set-AutomationVariable -Name "DatabaseServerName" -Value $serverName
}