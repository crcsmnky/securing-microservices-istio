istioctl manifest apply \
  --set profile=demo \
  --set values.global.mtls.auto=true \
  --set values.global.mtls.enabled=false