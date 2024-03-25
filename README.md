# bdb-usage-sizing
Simple bash script which leverages the REST API  to report on the usage and sizing of BDBs in one or more Redis Enterprise Clusters.

The script requires the utility jq to be installed, it will prompt the user if its not.
>apt install jq

Parameters are passed in a json file which has the following structure.
[
  	{
  		"cluster_name" : "any suitable cluster name",
  		"cluster_node" : "DN of any cluster node",
  		"cluster_admin" : "cluster admin user name"
  		
  	},
   
  	{
  		"cluster_name" : "cluster2",
  		"cluster_node" : "node1.mycluster.mydomain.com",
  		"cluster_admin" : "john.doe@mydomain.com  		
  	}
 ]
