<# 
	This PowerShell script was automatically converted to PowerShell Workflow so it can be run as a runbook.
	Specific changes that have been made are marked with a comment starting with “Converter:”
#>
<#
.SYNOPSIS 
    Creates Azure DB and upgrade the same to the specific service tier

.DESCRIPTION
 This runbook creates a database server with Firewall rules and creates the database from the queue

 
.NOTES
    AUTHOR: Siva Kumar Balaguru
    LASTEDIT: Oct 19, 2015 
    	
#>
workflow CreateSQLDB {  

    InlineScript 
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
 $StorageAccountName =Get-AutomationVariable -Name "StorageAccountName"
 $StorageAccountKey =Get-AutomationVariable -Name "StorageAccountKey"
 $Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
 $table=$Ctx|Get-AzureStorageTable
$sqlUserName=$servercredential.GetNetworkCredential().username
$sqlPassword=$servercredential.GetNetworkCredential().password
 if($table -ne $null)
 {
 $query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery
 $list = New-Object System.Collections.Generic.List[string]
 $list.Add("PartitionKey")
 $list.Add("RowKey")
 $list.Add("RequestNumber")
 $list.Add("status")
 $query.FilterString="status eq 0"
 $query.SelectColumns=$list
 $entities = $table.CloudTable.ExecuteQuery($query)
 ForEach($ent in $entities)
 {
                $DatabaseName=$ent.RowKey
                $repositorySize=$ent.PartitionKey
                if($repositorySize -eq "0")
                  { $ServiceTier="Basic" }
                  elseif($repositorySize -eq "1")
                   { $ServiceTier="S0" }
                   else
                   { $ServiceTier="S1"}

                $JobID=$ent.Properties["RequestNumber"].StringValue
                $output="" 
                $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $repositorySize, $DatabaseName
                $entity.Properties.Add("RequestNumber", $JobID)
                $entity.Properties.Add("status", 1)
                $entity.ETag="*"
                $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Replace($entity))

                $AzureSQLconnectionString=""
                $DBServerName=Get-AutomationVariable -Name "DatabaseServerName"			
        		
        		       				
				
				try
        		{
					$DBServer=Get-AzureSqlDatabaseServer -ServerName $DBServerName -ErrorAction Stop
					$ctx = $DBServer | New-AzureSqlDatabaseServerContext -Credential $serverCredential
				    $ServiceObjective=Get-AzureSqlDatabaseServiceObjective -Context $ctx -ServiceObjectiveName $ServiceTier
        	  		$DB=$DBServer | New-AzureSqlDatabase -DatabaseName $DatabaseName -ServiceObjective $ServiceObjective -Force -ErrorAction Stop	
                 
                }
                Catch [System.ServiceModel.CommunicationException]
                {
                
                    $status=3
					$ErrorCode=2
        		    $output= $output + $_.Exception
                    $AzureSQLconnectionString=""; 
                }
               Catch 
                { 
                    $status=3
					$ErrorCode=3
        		    $output= $output + $_.Exception
                    $AzureSQLconnectionString="";                    
                }
                if($DB -ne $null)
        		{
        		$output=$output + " Database $DatabaseName has been created successfully with $ServiceTier Service Tier"
                
                $AzureSQLconnectionString ="Server=tcp:$DBServerName.database.windows.net,1433;Database=$DatabaseName;User ID=$sqlUserName@$DBServerName;Password=$sqlPassword;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;"
                $status=2
				$ErrorCode=0
				
                }
        		else
        		{ $output=$output+" Unable to create the Database"
                  $status=3
                 if($ErrorCode -ne 2) { $ErrorCode=3 }
				}
                $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $repositorySize, $DatabaseName
                $entity.Properties.Add("RequestNumber", $JobID)
                $entity.Properties.Add("status", $status)
                $entity.Properties.Add("ErrorCode", $ErrorCode)
                $entity.Properties.Add("ConnectionString", $AzureSQLconnectionString)
                $entity.Properties.Add("ErrorMessage", $output)
                $entity.ETag="*"
                $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Replace($entity))
                $output
               
  
 }
 }

         
 
 }
 }
              
             
        

	
    
   
       
		

