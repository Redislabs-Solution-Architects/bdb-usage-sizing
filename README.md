# bdb-usage-sizing
Simple bash script which leverages the REST API  to report on the usage and sizing of BDBs in one or more Redis Enterprise Clusters.

The script requires the utility jq to be installed, it will prompt the user if its not.
>apt install jq

Test Parameters are passed via a json file. 
See sample_test_config.json

Usage:

>./redisUsageReport.sh -f config_file.json

Output:

The output is a csv file named Report-yyyyMMddHHmmss.csv. It contains the following headers.

cluster_name,expiration_date,shards_limit,ram_shards_in_use,db_name,version,usage_category,memory_size,data_persistence,replication,sharding,shard_count

usage_category - A calculated field which categorized the DB as CACHE or DataBase, based on features enabled. e.g. persistance, backup, eviction, search
expiration_date -  expiration date of the license (cluster level attribute)
shards_limit -  number of shards licensed (cluster level attribute)
ram_shards_in_use - number of shards which have been used (cluster level attribute)