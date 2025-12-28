Command to create EKS cluster on AWS free tier account




eksctl create cluster \
  --name intent-prediction \
  --region us-east-1 \
  --version 1.29 \
  --managed \
  --nodegroup-name intent-workers \
  --node-type c7i-flex.large \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3

## Command to create cluster for converter applicatin for Dynatrace Practice
eksctl create cluster \
  --name converter-application \
  --region us-east-1 \
  --version 1.29 \
  --managed \
  --nodegroup-name converter-workers \
  --node-type c7i-flex.large \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3

