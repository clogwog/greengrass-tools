#!/bin/sh
#set -x

deployment_template="{ \"targetArn\": \"arn:aws:iot:TEMPLATE_REGION:TEMPLATE_AWSACCOUNT:thinggroup/TEMPLATE_DEPLOYMENT_THING_GROUP\", \"deploymentName\": \"TEMPLATE_DEPLOYMENT_NAME\", \"components\": TEMPLATE_COMPONENTS , \"deploymentPolicies\": { \"failureHandlingPolicy\": \"DO_NOTHING\", \"componentUpdatePolicy\": { \"timeoutInSeconds\": 600, \"action\": \"NOTIFY_COMPONENTS\" }, \"configurationValidationPolicy\": { \"timeoutInSeconds\": 600 } },  \"iotJobConfiguration\": {} } "


usage() {
    echo ""
    echo "description: a script to only update 1 component version in a deployment"
    echo "usage      : $0 -d [deployment-name] -g [deployment-group]  -c [component-name] -v [new-component-version]"
    echo "optional   :                        -r [aws-region] -a [aws-account-number]"
    echo ""
    echo "example    : $0 -d 7kLatest -g 7kLatest -c au.com.mtdata.smartdvr.docker -v 0.0.3 -r ap-southeast-2"

}

while getopts ":d:g:c:v:r:a:" flag
do
    case "${flag}" in
        d) deploymentName=${OPTARG};;
        g) deploymentGroup=${OPTARG};;
        c) componentName=${OPTARG};;
        v) newComponentVersion=${OPTARG};;
        r) region=${OPTARG};;
        a) account=${OPTARG};;
    esac
done

if [ -z "$deploymentName" ] || [ -z "$deploymentGroup" ] || [ -z "$componentName" ] || [ -z "$newComponentVersion" ]
then
    usage
    exit 1
fi

if [ -z "$region" ]
then
    region=$(aws configure get region)
fi
if [ -z "$account" ]
then
    account=$(aws sts get-caller-identity --query Account --output text)
fi

deploymentId=$(aws greengrassv2 list-deployments --target-arn arn:aws:iot:$region:$account:thinggroup/$deploymentName | jq -r .deployments[0].deploymentId)
deploymentJson=$(aws greengrassv2 get-deployment --deployment-id=$deploymentId)
components=$( echo $deploymentJson | jq  .components )
updatedComponentsJson=$( echo $components | jq  -c --arg newComponentVersion "$newComponentVersion" '."au.com.mtdata.smartdvr.docker".componentVersion = $newComponentVersion')

#merge deployment_template
echo $deployment_template > ./tmpDeployment.json

sed   -i "s|TEMPLATE_DEPLOYMENT_NAME|${deploymentName}|g"  ./tmpDeployment.json
sed   -i "s|TEMPLATE_DEPLOYMENT_THING_GROUP|${deploymentGroup}|g" ./tmpDeployment.json
sed   -i "s|TEMPLATE_REGION|${region}|g" ./tmpDeployment.json
sed   -i "s|TEMPLATE_COMPONENTS|${updatedComponentsJson}|g" ./tmpDeployment.json
sed   -i "s|TEMPLATE_AWSACCOUNT|${account}|g" ./tmpDeployment.json

cat ./tmpDeployment.json

SCRIPTHOME="$( cd "$(dirname "$0")"/.. ; pwd -P )"

aws greengrassv2 create-deployment --cli-input-json file://${SCRIPTHOME}/tmpDeployment.json

rm -f ./tmpDeployment.json
