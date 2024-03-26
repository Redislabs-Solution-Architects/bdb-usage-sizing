#!/bin/bash


function usage() {
	echo "Description:"
    echo "This script leverages the Redis Rest API to report on the DB configuration within one or more Redis Enterprise Clusters."
	echo ""
	echo "Dependancy:"
	echo "jq - json parsing utility must be installed"
	echo "apt install jq"
	echo ""
	echo ""
	echo "Usage:"
    echo "./generateRedisDBReport.sh -f <config file>"
	echo ""
    echo "see sample config file - sample_test_config.json"
}



# Check for arguments
if [[ $# -eq 0 || $1 == '-h' || $1 == '--help' ]]; then
	usage
	exit 1
fi


# Parse the command-line arguments
while getopts ":f:h:" opt; do
    case "$opt" in
        f)
            filename="$OPTARG"
            ;;
        h)
            usage
            exit 1
            ;;
        \?)
            echo "Error: Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done


	report_file="report-$(date +"%Y%m%d%H%M%S").csv"
	

# Read the file content
if [ -e "$filename" ]; then

	##############################################
	#check to see if jq is installed
	##############################################
	
	jq_installer=$(jq --version)

	if [[ "$jq_installer" == "jq-"* ]]; then
			echo "jq Intallation Check: PASSED"
			echo ""
		else 
			echo "Dependency jq is missing. Install jq"
			echo ">apt install jq -y"	
			exit 1
	fi	
	

	
	
	##############################################
	#load the config data from the file
	##############################################
		
	
	echo "Loading Config File"
	echo ""	
	
	cluster_name_arr=()
	cluster_node_arr=()
	cluster_admin_arr=()
	cluster_pwd_arr=()
	
	while read item; do
		cluster_name=$(jq --raw-output '.cluster_name' <<< "$item")
		cluster_node=$(jq --raw-output '.cluster_node' <<< "$item")
		cluster_admin=$(jq --raw-output '.cluster_admin' <<< "$item")
		cluster_api_port=$(jq --raw-output '.cluster_api_port' <<< "$item")

		if [[ "$cluster_api_port" == null ]]; then
				cluster_api_port="9443"
		fi
		
		cluster_name_arr+=($cluster_name)
		cluster_node_arr+=($cluster_node)
		cluster_admin_arr+=($cluster_admin)
	done < <(jq -c '.[]' $filename)
	
	
	##############################################
	#prompt the user for passwords
	##############################################
	for cluster in "${cluster_name_arr[@]}"; do
		read -p "Enter Password for Cluster $cluster: " pwd
		cluster_pwd_arr+=($pwd)
	done

	echo ""
	
	#Load the header columns of the report file
    echo "cluster_name,expiration_date,shards_limit,ram_shards_in_use,db_name,version,usage_category,memory_size,data_persistence,replication,sharding,shard_count" > $report_file

	##############################################
	#load data for each cluster
	##############################################	    
	
	for ((i = 0; i < ${#cluster_name_arr[@]}; i++)); do
		
		
		cluster_name="${cluster_name_arr[i]}"
		cluster_node="${cluster_node_arr[i]}"
		cluster_admin="${cluster_admin_arr[i]}"
		admin_pwd="${cluster_pwd_arr[i]}"
		cluster_fqdn=$cluster_name
	
		##############################################
		#REST API Endpoints
		##############################################	 	
		CLUSTER_API_URL="https://$cluster_node:$cluster_api_port/v1/cluster"	
		CLUSTER_LICENSE_API_URL="https://$cluster_node:$cluster_api_port/v1/license"		
		BDB_API_URL="https://$cluster_node:$cluster_api_port/v1/bdbs?fields=uid,name,backup,data_persistence,eviction_policy,memory_size,module_list,replication,sharding,shards_count,version"

	
		#Test Connection to REST API
		HTTP_CODE=$(curl -s -k -L -X GET -u "$cluster_admin:$admin_pwd" -w "%{http_code}" -H "Content-type:application/json"  $CLUSTER_API_URL)
		
		
		if [[ "$HTTP_CODE" == *"200" ]]; then
		
			##############################################
			# get details for the cluster
			##############################################	

			while read item; do
				cluster_fqdn=$(jq --raw-output '.name' <<< "$item")
			done < <(curl -s -k -L -X GET -u "$cluster_admin:$admin_pwd" -H "Content-type:application/json"  $CLUSTER_API_URL | jq -c '.')

			##############################################
			# get details for the cluster license
			##############################################	

			while read item; do
				expiration_date=$(jq --raw-output '.expiration_date' <<< "$item")
				shards_limit=$(jq --raw-output '.shards_limit' <<< "$item")
				ram_shards_in_use=$(jq --raw-output '.ram_shards_in_use' <<< "$item")			
			done < <(curl -s -k -L -X GET -u "$cluster_admin:$admin_pwd" -H "Content-type:application/json"  $CLUSTER_LICENSE_API_URL | jq -c '.')

			##############################################
			# get details for the cluster data bases
			##############################################
			
			echo "Getting DB Details For Cluster: $cluster_name - $cluster_fqdn"
			echo ""			
			
			while read  cluster_db; do
				db_name=$(jq --raw-output '.name' <<< "$cluster_db")
				version=$(jq --raw-output '.version' <<< "$cluster_db")
				data_persistence=$(jq --raw-output '.data_persistence' <<< "$cluster_db")
				memory_size=$(jq --raw-output '.memory_size' <<< "$cluster_db")
				replication=$(jq --raw-output '.replication' <<< "$cluster_db")
				sharding=$(jq --raw-output '.sharding' <<< "$cluster_db")
				shard_count=$(jq --raw-output '.shards_count' <<< "$cluster_db")
				backup=$(jq --raw-output '.backup' <<< "$cluster_db")	
				eviction_policy=$(jq --raw-output '.eviction_policy' <<< "$cluster_db")							
			
				# find the usage type i.e. CACHE or DB
				usage_category="CACHE"			
							
				if [[ "$data_persistence" != "disabled" || $backup == true || $eviction_policy == "noeviction" ]]; then
					usage_category="DataBase"	
				fi
				
				#check the modules enabled
				module_list_arr=$(jq --raw-output '.module_list' <<< "$cluster_db")
								
				while read module_list; do
					module_name=$(jq --raw-output '.module_name' <<< "$module_list")
					
					#check to see if search is enabled
					if [[ "$module_name" == "search" ]]; then
						#echo "Search Module Enabled"
						usage_category="DataBase"	
					fi				
				
				done < <(echo "$(echo "$module_list_arr" | jq -c '.[]')")
			
				#write the record for the DB to the report file
				echo "$cluster_fqdn,$expiration_date,$shards_limit,$ram_shards_in_use,$db_name,$version,$usage_category,$memory_size,$data_persistence,$replication,$sharding,$shard_count" >> $report_file
							
			
			
			done < <(curl -s -k -L -X GET -u "$cluster_admin:$admin_pwd" -H "Content-type:application/json"  $BDB_API_URL | jq -c '.[]')
			
		elif [[ "$HTTP_CODE" == *"401" ]]; then
			echo "Authentication Error: Invalid Credentials passed for cluster: $cluster_name"
			echo "Error Code: $HTTP_CODE"
			#rm  -r $report_file
			#exit 1		
		elif [[ "$HTTP_CODE" == *"000" ]]; then
			echo "General Error: When executing API for cluster: $cluster_name"
			echo "Most likely cause: Cluster node could not be reached."
			echo "Error Code: $HTTP_CODE"
			#rm  -r $report_file
			#exit 1		
		else 
			echo "Error Executing Redis API for Cluster $cluster_name"
			echo "Error Code: $HTTP_CODE"
			#rm  -r $report_file
			#exit 1
		fi	
	done
	
	echo "Report Saved in file: $report_file"
	
else
    echo "Error: File $filename not found or could not be accessed"
    exit 1
fi