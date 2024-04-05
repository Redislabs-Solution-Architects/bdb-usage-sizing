# Redis Database Usage Report

A simple bash script which leverages the Redis Enterprise REST API to generate a report on the usage and sizing of Redis instances in one or more Redis Enterprise Clusters.

The script requires the utility jq to be installed, it will prompt the user if its not.
```$ apt install jq ```

Test Parameters are passed via a json file. 
See [sample_test_config.json](sample_test_config.json).

### Usage:

Edit the input configuration file with the details of your clusters. Please note that you will be _prompted_ for passwords so they are not required to be saved in this file. 
From the location that you saved the file:
` $ ./redisUsageReport.sh -f config_file.json ` or `$ bash redisUsageReport.sh -f config_file.json `

The input configuration file `config_file.json` is JSON formatted and should have the following structure:
```
[
  {
    "cluster_name" : "<required: arbitrary cluster name>",
    "cluster_node" : "<required: cluster fqdn>",
    "cluster_admin" : "<required: admin email address>"
    "cluster_api_port" : "<optional; default is 9443>"
  },
  { ... }
]
```

### Output:

The output is a csv file named `report-yyyyMMddHHmmss.csv`. Please see the following [sample output](report-20240327011814.csv).

It contains the following headers and their corresponding values.

```cluster_name,expiration_date,shards_limit,ram_shards_in_use,db_name,version,usage_category,memory_size,data_persistence,replication,sharding,shard_count```

## Privacy
Please note that no proprietary information will be extracted. 
