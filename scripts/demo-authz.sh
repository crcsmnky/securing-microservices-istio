#!/bin/bash

. $(dirname ${BASH_SOURCE})/util.sh


SOURCE_DIR=$PWD

desc "Update frontend, and checkout service to use specific service accounts"
run "kubectl apply -f <(istioctl kube-inject -f ../authz-policy/hipstershop-sa.yaml)"

desc "Limit access to currecnty service through checkoutservice only"
run "cat ../authz-policy/authz-checkout-only.yaml"
run "kubectl apply -f  ../authz-policy/authz-checkout-only.yaml"

desc "Go check UI"
read -s

backtotop
desc "Uh oh. Let's add policy to be able to call currecny from frontend"
run "cat ../authz-policy/authz-checkout-frontend.yaml"
run "kubectl apply -f  ../authz-policy/authz-checkout-frontend.yaml"
backtotop

desc "clean up policy"
read -s
run "kubectl delete authorizationpolicy authz-currency -n default"
