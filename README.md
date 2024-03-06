## DevOps project 001

### Tech Stack
- AWS
- EKS
- Spinnaker
- Docker
- Golang
- Terraform
- Grafana
- Prometheus
- Github Actions pipeline

### Pre requisites
- Account on AWS
- awscli
- kubectl
- docker/podman
- helm

### Step by step
- Package the app service using a Dockerfile
- Create a registry in AWS using terraform 
- Create an EKS cluster using terraform
- Deploy Spinnaker to the cluster using helm
- Configure the pipeline to push the image to the registry
- Create k8s manifests (deploy, svc, hpa)
- Configure spinnaker to deploy the k8s manifests if it identifies a new image
- Configure blue/green deployment with spinnaker
- Configure canary deployment with spinnaker
- Make spinnaker publicly accessible
- Configure cert-manager
- Configure Prometheus and Grafana LTM stack in the cluster

### Deployment

Examples of deployment using blue/green and canary with Spinnaker