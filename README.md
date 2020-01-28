# Securing Microservices using Istio 1.4

## Contents
- [Infrastructure Setup](#infrastructure-setup)
- [Deploy Sample App](#deploy-sample-app)
- [Enable Auto mTLS](#enable-auto-mtls)
- [Enable Authorized Service Access](#enable-authorized-service-access)
- [Cleanup](#cleanup)

## Infrastructure Setup

First, create the GKE cluster:

```bash
gcloud beta container clusters create [CLUSTER_NAME] \
    --machine-type=n1-standard-4 \
    --cluster-version=latest \
    --enable-stackdriver-kubernetes --enable-ip-alias \
    --scopes cloud-platform
```

Grab the cluster credentials - you'll need them for `kubectl` commands to work:

```bash
gcloud container clusters get-credentials [CLUSTER_NAME]
```

Make yourself a `cluster-admin` so you can install Istio:

```bash
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)
```

Next, grab the latest release of Istio:

```bash
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.4.3 sh -
cd istio-1.4.3
```

Use `istioctl` to install the Istio control plane components, using the `demo` profile (not for production):

```bash
bin/istioctl manifest apply \
  --set profile=demo \
  --set values.global.mtls.auto=true \
  --set values.global.mtls.enabled=false
```

Finally, enable Istio's sidecar proxy auto-injection for the `default` namespace:

```bash
kubectl label ns default istio-injection=enabled
```

## Deploy Sample App

[Hipster Shop](GoogleCloudPlatform/microservices-demo) will serve as the sample app to test automatic mTLS and service authorization.

Deploy the Hipster Shop sample app:

```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
```

Next, deploy the Istio manifests for Hipster Shop:

```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml
```

## Enable Auto mTLS

In Istio 1.4, when using the `values.global.mtls.auto=true` installation flag, only `Policy` objects are required to enable mTLS.

Enable automatic mTLS by deploying the following `Policy` objects:

```bash
kubectl apply -f auto-mtls/policy-mtls-enable.yaml
```

After a few moments, use `istioctl` to very auto mTLS settings have taken effect:

```bash
FRONTEND=$(kubectl get pods -l app=frontend -o jsonpath={.items..metadata.name})
bin/istioctl authn tls-check $FRONTEND.default
```

In the output, you should see that services in the `default` Namespace show `STATUS` as `AUTO` and `SERVER` as `STRICT`.

## Enable Authorized Service Access

In Istio 1.4, `AuthorizationPolicy` replaces `ClusterRbacConfig`, `ServiceRole`, and `ServiceRoleBinding` for controlling service to service authorization. Refer to [Introducing the Istio v1beta1 Authorization Policy](https://istio.io/blog/2019/v1beta1-authorization-policy/) for more details.

First, create [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) for `frontend` and `checkoutservice`, and update those Deployments to include them:

```bash
kubectl apply -f authz-policy/hipstershop-sa.yaml
```

Next, apply authorization controls for `currencyservice`, only allowing access from `checkoutservice`:

```bash
kubectl apply -f authz-policy/authz-checkout-only.yaml
```

Now test out unauthorized service access by first grabbing the `istio-ingressgateway` `LoadBalancer` IP:

```bash
INGRESS=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath={.status.loadBalancer.ingress..ip})
```

Open a browser to `http://$INGRESS` and you'll see an `RBAC: access denied` message. That's because `frontend` is not authorized to access `currencyservice`. 

To fix that error, apply updated authorization controls for `currencyservice` that allow `checkoutservice` and `frontend` service to access it:

```bash
kubectl apply -f authz-policy/authz-checkout-frontend.yaml
```

Refresh `http://$INGRESS` and you should see that things are working once again.

## Cleanup

The simples way to cleanup is to delete the GKE cluster:

```bash
gcloud container clusters delete [CLUSTER_NAME]
```
