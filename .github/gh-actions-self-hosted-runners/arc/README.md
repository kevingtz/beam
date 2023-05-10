<!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
-->

# Actions Runner Contoler 

# Installing

TODO: steps to run terraform 


# DEV Docs  *temporary*

1. Create a file called `overrides.tfvars` with the following contents:
```
project_id = "PROJECT_ID" # google PROJECT_ID that you want to deploy in
region = "gcp_region"     # GCP region for the network
zone = "europe-west3-c"   # GCP zone for the nodes
min_main_node_count = "1" # Minimal and initial node count for main pool
max_main_node_count = "5" # Maximal node count for main pool
min_memory_node_count = "0" # Minimal and initial node count for Memory pool
max_memory_node_count = "2" # Maximal node count for Memory pool
environment = "vdjerek" # Name of the environment. Used as a prefix like dev- stag- anything-
ingress_domain = "fqdn" # FQDN for webhook ingress
github_app_id = "app_id" # Github App app_id
github_app_installation_id = "install_id" # Github App install id
github_app_private_key_path = "absolute_path_to_key" # Absolute filesystem path to .pem keyfile generated in the Github App
```
2. Create a google bucket for storing the terraform state. Make sure you disable public access and allow your account to access it. 


3.  Init terraform with: 
```
terraform init -backend-config="bucket=bucket_name"
```
4. Terraform apply
```
terraform apply -var-file=overrides.tfvar
```