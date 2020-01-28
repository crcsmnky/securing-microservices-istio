#echo $(k get pod -n istio-system -l istio=ingressgateway -o jsonpath='{.items[0].status.hostIP}'):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

URL=$(k get svc -n istio-system | grep ingressgateway | awk '{ print $4 }')

echo $URL

