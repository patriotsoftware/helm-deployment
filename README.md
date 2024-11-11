# Helm Deployment Action

This action will pull down a base Helm chart and deploy a service to Kubernetes.

## Major changes from previous actions:
* Removal of `monochart:latest` check. This will now pull the intended image. I.E. "{ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/monochart" -> will pull the latest chart version. If a non-latest version is desired, the Chart Version variable will be appended to the pull like so: `--version {CHART_VERSION}`