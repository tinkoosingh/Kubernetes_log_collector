#!/bin/bash
log="0"
metric="0"
elastic="0"


while getopts lme flag
do
    case "${flag}" in
       l) log="1";;
        m) metric="1";;
        e) elastic="1";;
    esac
done

nmspace=$(kubectl get namespace | grep -w "aiops")
if [[ $nmspace == "" ]]
then
	printf "Creating namespace aiops\n"
	kubectl create namespace aiops
fi


metric_addons_status=$(minikube addons list | grep "metrics-server" | awk -F ' ' '{print $6}')

if [[ $metric_addons_status != "enabled" ]]
then
	minikube addons enable metrics-server
fi

kubectl apply -f rbc.yaml




if [[ $log == "0" && $metric == "0" && $elastic == "0" ]]
then
		
	elastic_pod=$(kubectl get pod -n aiops | awk '/elasticsearch/{sub(/.*elasticsearch/, ""); print $1}')
		
	if [[ $elastic_pod == *"elasticsearch"* ]]
	then 
		printf "ELASTICSEARCH AVAILABLE\n"
	else	
		printf "DEPLOYING ELASTICSEARCH\n"
			
		helm install database eskibana --values eskibana/values.yaml --namespace=aiops
	fi

	helm install log logcollector/ --values logcollector/values.yaml --namespace=aiops
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install --namespace aiops node-exporter prometheus-community/prometheus-node-exporter
	helm install metric metriccollector/ --values metriccollector/values.yaml --namespace=aiops 

elif [[ $elastic == "1" ]]
then
	helm install database eskibana --values eskibana/values.yaml --namespace=aiops

else
		
	elastic_pod=$(kubectl get pod -n aiops | awk '/elasticsearch/{sub(/.*elasticsearch/, ""); print $1}')
	
	if [[ $elastic_pod == *"elasticsearch"* ]]
	then 
		printf "ELASTICSEARCH AVAILABLE\n"
	else	
		printf "DEPLOYING ELASTICSEARCH\n"
				
		helm install database eskibana --values eskibana/values.yaml --namespace=aiops
	fi
	
	if [[ $log == "1" ]]
	then
		helm install log logcollector/ --values logcollector/values.yaml --namespace=aiops
	fi

	if [[ $metric == "1" ]]
	then
		helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
		helm repo update
		helm install --namespace aiops node-exporter prometheus-community/prometheus-node-exporter
		helm install metric metriccollector/ --values metriccollector/values.yaml --namespace=aiops 
	fi
fi	




