Here is your list of commands, organized in the **exact sequential order** they must be run, with the critical intermediate configuration steps (StorageClass patch, Kagent system secrets, and ModelConfig patch) integrated:

### 1. Cluster Creation
```bash
eksctl create cluster \
  --name kagent-cluster \
  --region us-east-1 \
  --version 1.30 \
  --managed \
  --nodegroup-name kagent-workers \
  --node-type c7i-flex.large \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --with-oidc
```

### 2. Storage Setup (EBS CSI Driver & Default StorageClass)
```bash
# Create the IAM role association
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster kagent-cluster \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve

# Install the driver
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster kagent-cluster \
  --service-account-role-arn arn:aws:iam::520622116374:role/AmazonEKS_EBS_CSI_DriverRole \
  --force

# Mark gp2 as default StorageClass (CRITICAL so the PostgreSQL database PVC binds successfully)
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### 3. Kagent Installation
```bash
# Install CRDs
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --namespace kagent-system \
  --create-namespace

# Install Core Kagent Controllers
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --namespace kagent-system \
  --create-namespace
```

### 4. Secrets & Model Configuration Setup (CRITICAL to resolve controller crash loops and agent config errors)
```bash
# 1. Create the Gemini API key secret for the BYO infra-agent (in the default namespace)
kubectl create secret generic infra-agent-secrets \
  -n default \
  --from-literal=gemini-api-key="YOUR_GEMINI_API_KEY"

# 2. Create the placeholder secret (required to pass agent pod config checks and allow them to start)
kubectl create secret generic kagent-openai \
  -n kagent-system \
  --from-literal=OPENAI_API_KEY="placeholder"

# 3. Create the Gemini API key secret for Kagent's own models
kubectl create secret generic kagent-gemini \
  -n kagent-system \
  --from-literal=GOOGLE_API_KEY="YOUR_GEMINI_API_KEY"

# 4. Patch default ModelConfig to route reasoning tasks through Gemini 3.5 Flash
kubectl patch modelconfig default-model-config -n kagent-system --type='merge' -p '{
  "spec": {
    "provider": "Gemini",
    "model": "gemini-3.5-flash",
    "apiKeySecret": "kagent-gemini",
    "apiKeySecretKey": "GOOGLE_API_KEY"
  }
}'
```
