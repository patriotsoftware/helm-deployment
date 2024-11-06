# Helm Deployment Action

This action will pull down a base Helm chart and deploy a service to Kubernetes.

## Major changes from previous actions:
* Removal of `monochart:latest` check. This will now pull the intended image.
* Timeout is default now to 2 minutes and 30 seconds. Only repos with special timeouts will need to be adjusted.