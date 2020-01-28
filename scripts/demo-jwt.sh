#!/bin/bash

. $(dirname ${BASH_SOURCE})/util.sh


SOURCE_DIR=$PWD

URL=$(kubectl get svc -n istio-system | grep ingressgateway | awk '{print $4}')

echo "URL to use $URL"
read -s

desc "We can call frontend:"
read -s 
tmux split-window -v -d -c $SOURCE_DIR
tmux send-keys -t 1 "curl -v -I $URL" C-m
read -s

desc "Let's add a new policy on customer to require a JWT auth token"
run "cat $(relative ../auth-jwt/frontend-jwt-policy-keycloak.yaml)"

desc "Let's create this policy"
run "kubectl apply -f $(relative ../auth-jwt/frontend-jwt-policy-keycloak.yaml)"

desc "We should wait a few moments for the changes to propagate"
read -s

desc "Now let's try call the frontend service again"
tmux send-keys -t 1 "curl -v -I $URL" C-m

desc "Ouch! we got denied!"
read -s 
desc "Let's call with a JWT token"
desc "We'll ask keycloak for a token:"
TOKEN=$(kubectl run -i --rm --restart=Never tokenizer --image=tutum/curl --command -- curl -s -X POST 'http://keycloak.default:8080/auth/realms/istio/protocol/openid-connect/token' -H "Content-Type: application/x-www-form-urlencoded" -d 'username=demo&password=demo&grant_type=password&client_id=httpbin'  | jq .access_token | sed 's/\"//g')
echo $TOKEN

read -s


desc "Now let's try calling again with the token!"
read -s 

tmux send-keys -t 1 "curl -v -I --header \"Authorization: Bearer $TOKEN\" $URL" C-m
read -s

desc "Clean up"
run "kubectl delete policy frontend-jwt-policy -n default"

