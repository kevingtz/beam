#!/bin/bash

set -e

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -f|--folder)
      BEAM_FOLDER="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--credentials)
      GOOGLE_APPLICATION_CREDENTIALS="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--tag)
      DOCKER_TAG="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--service)
      SERVICE="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--projectid)
      PROJECT_ID="$2"
      shift # past argument
      shift # past value
      ;;
    #TMP: Until we wont have redis address in terraform state bucket
    #Currently in Beam GCP IP is 10.160.154.59
    -r|--redis)
      REDIS_IP="$2"
      shift # past argument
      shift # past value
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters
cd $BEAM_FOLDER
echo "-------------------D E P L O Y   G O   B A C K E N D-----------------"
echo "PATH TO GCP CREDS   = ${GOOGLE_APPLICATION_CREDENTIALS}"
echo "DOCKER TAG          = ${DOCKER_TAG}"
echo "SERVICE NAME        = ${SERVICE}"
echo "GCP PROJECT ID      = ${PROJECT_ID}"
echo "............"
echo "LOG IN TO DOCKER"
cat $GOOGLE_APPLICATION_CREDENTIALS | docker login -u _json_key --password-stdin https://us-central1-docker.pkg.dev/$PROJECT_ID/playground-repository
echo "RUNNING DOCKER IMAGE BUILD"
./gradlew playground:backend:containers:go:dockerTagPush -Pdocker-repository-root="us-central1-docker.pkg.dev/${PROJECT_ID}/playground-repository" -Pdocker-tag="${DOCKER_TAG}" 
echo "RUNNING DEPLOY TO GCP"
cd $BEAM_FOLDER/playground/terraform/applications/backend-router
terraform apply  -var="project_id=${PROJECT_ID}" -var="docker_registry_address=us-central1-docker.pkg.dev/${PROJECT_ID}/playground-repository" -var="docker_image_tag=${DOCKER_TAG}" -var="docker_image_name=beam_playground-backend-go" -var="service_name=${SERVICE}" -var="cache_address=${REDIS_IP}"
