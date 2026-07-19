Command to create EKS cluster on AWS free tier account


eksctl create cluster \
  --name intent-prediction \
  --region us-east-1 \
  --version 1.30 \
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

# To install psql
choco install postgresql -y

# for eks dynatrace integration
mongo:4.2.24 is compatible with mongosh

## To install EBS-CSI driver add-on
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster converter-application

You need the EBS CSI driver when your StorageClass uses EBS volumes for dynamic provisioning in Amazon EKS.

Your StorageClass looks like this:

`provisioner: ebs.csi.aws.com`

The EBS CSI driver is used by activategate component deployed by the operator as it is deployed as stateful set

✅ EBS CSI Driver

The EBS CSI driver in Amazon EKS allows Kubernetes to dynamically create and attach EBS volumes to pods using PersistentVolumeClaims.
It enables storage provisioning via AWS APIs from inside the cluster.

✅ OIDC (OpenID Connect)

OIDC lets Kubernetes service accounts securely assume IAM roles using web identity tokens.
It enables IRSA (IAM Roles for Service Accounts) without storing AWS credentials in pods.

✅ Trust Policy

A Trust Policy is an IAM role policy that defines who is allowed to assume the role.
In EKS, it allows a specific Kubernetes service account (via OIDC) to assume the IAM role. 🚀
Trust policy is applied to an IAM role to allow a specific Kubernetes service account to assume that role using OIDC.

🔎 So Flow Becomes:

IAM Role
⬇
Trust Policy
⬇
ServiceAccount (annotated with role ARN)
⬇
Deployment uses that ServiceAccount
⬇
Pods assume the role

# To increase the nodes in the nodegroup 
eksctl scale nodegroup \
  --cluster <cluster-name> \
  --name <nodegroup-name> \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3


## Commands to run after cluster creation

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster kagent-cluster \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve
  
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster kagent-cluster \
  --service-account-role-arn arn:aws:iam::520622116374:role/AmazonEKS_EBS_CSI_DriverRole \
  --force

## Command to pass the Gemini API key
kubectl create secret generic infra-agent-secrets \
  --from-literal=gemini-api-key="YOUR_GEMINI_API_KEY"


## Kagent Installation

helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --namespace kagent-system \
  --create-namespace

helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --namespace kagent-system \
  --create-namespace
  

