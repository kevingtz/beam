# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

apt-get -qq  update  
apt-get -qq  install -y wget unzip software-properties-common git curl apt-transport-https ca-certificates gnupg jq lsb-release
                  
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |tee /etc/apt/sources.list.d/docker.list
      
wget -nv https://releases.hashicorp.com/terraform/1.4.2/terraform_1.4.2_linux_amd64.zip 
unzip terraform_1.4.2_linux_amd64.zip
mv terraform /usr/local/bin/terraform

curl -fsSLo get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh && ./get_helm.sh

apt-get -qq update
apt-get -qq install -y google-cloud-sdk-gke-gcloud-auth-plugin google-cloud-sdk openjdk-11-jdk kubectl docker-ce 

git clone --branch $BRANCH_NAME $REPO_NAME --single-branch
cd beam
mkdir playground/terraform/environment/$ENVIRONMENT_NAME
 
gcloud storage buckets create gs://$TF_VAR_state_bucket --location $TF_VAR_region --project $TF_VAR_project_id --pap
if [ $? -eq 0 ]
then 
        echo "Creation successfull"
else
        echo "Cannot create bucket, please check if the name is unique"
        exit 1
fi

echo "---- ENV OUTPUT---"
env | grep TF_VAR
echo "bucket = \"${TF_VAR_state_bucket}\"" > playground/terraform/environment/$ENVIRONMENT_NAME/state.tfbackend
echo "---- FILE OUTPUT ---"
cat playground/terraform/environment/$ENVIRONMENT_NAME/state.tfbackend

./gradlew playground:terraform:InitInfrastructure -Pproject_environment=$ENVIRONMENT_NAME
