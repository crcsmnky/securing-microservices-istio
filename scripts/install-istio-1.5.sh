# This is pinned to istio istio-1.5-alpha.32ad484968f3cf25d79927ac5b12b51de620be5e
# also to installer 26a4808f7d920f557ee1fab884aa1a2d343978a4
# should update this when istio 1.5 becomes more stable

istioctl manifest generate --set values.telemetry.v2.enabled=true --set values.telemetry.v1.enabled=false --set telemetry.enabled=false --set policy.enabled=false --set values.global.useMCP=false --set configManagement.enabled=false --set values.pilot.useMCP=false --set security.enabled=false --set values.prometheus.security.enabled=false --set values.global.mtls.enabled=true --set values.global.mtls.auto=true --set values.global.controlPlaneSecurityEnabled=false --set values.prometheus.enabled=false --set installPackagePath=/Users/ceposta/go/src/istio.io/installer | k apply -f -