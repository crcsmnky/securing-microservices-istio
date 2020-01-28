#!/bin/bash

. $(dirname ${BASH_SOURCE})/util.sh


SOURCE_DIR=$PWD

desc "Let's check that mTLS is disabled:"
run "kubectl get meshpolicy default -o yaml"

desc "Let's verify mtls is enabled using the istioctl cli"
FRONTEND=$(kubectl get pods -l app=frontend -o jsonpath={.items..metadata.name})
run "istioctl authn tls-check $FRONTEND.default"

desc "Let's capture traffic from frontend->productcatalog with tcpdump"
desc "We'll figure out the IP of the productcatalog pod and watch traffic to/from there"
run "kubectl get pod"


TARGET_POD_IP=$(kubectl get pod -o wide | grep productcatalogservice | awk '{ print $6 }')
echo "Product Catalog Service IP: $TARGET_POD_IP"
read -s

backtotop
desc "We need to change the perms on the frontend pod... brb..."

# split the screen and run the polling script in bottom script
tmux split-window -v -d -c $SOURCE_DIR
tmux select-pane -t 1
tmux send-keys -t 1 "kubectl edit deploy frontend" C-m
read -s 


backtotop

desc "let's capture traffic"
CAPTURE_POD=$(kubectl get pod | grep -i running|  grep frontend | awk '{ print $1}' )
kubectl exec $CAPTURE_POD -c istio-proxy -- sh -c 'rm /opt/output*.* > /dev/null 2>&1'

run "kubectl exec -it $CAPTURE_POD  -c istio-proxy -- sh -c \"sudo tcpdump -i eth0 '((tcp) and (net $TARGET_POD_IP))' -w /opt/output.pcap\""


desc "Let's copy the pcap file over to our local machine so we can take a look"
rm -f ~/temp/output.pcap > /dev/null 2>&1
run "kubectl cp -c istio-proxy default/$CAPTURE_POD:opt/output.pcap /Users/ceposta/temp/output.pcap"

