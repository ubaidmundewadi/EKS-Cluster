Side Question: provide me the command and explanation to install nginx-ingress controller

To install the **NGINX Ingress Controller** on an AWS EKS cluster, the standard and recommended approach is using **Helm**.

---

### Installation Commands

#### Step 1: Add and update the official Helm repository
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

#### Step 2: Install the controller with an AWS Network Load Balancer (NLB)
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing"
```

*(Alternatively, without Helm, you can apply the community-maintained AWS static manifest directly:)*
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

---

### Command Breakdown and Explanation

| Flag / Parameter | Purpose |
| :--- | :--- |
| `helm repo add ingress-nginx ...` | Registers the official Kubernetes SIG Network Helm repository containing the `ingress-nginx` chart. |
| `helm repo update` | Downloads the latest chart metadata and version index to your local environment. |
| `helm install ingress-nginx ingress-nginx/ingress-nginx` | Deploys a new release named `ingress-nginx` using the `ingress-nginx` chart. |
| `--namespace ingress-nginx --create-namespace` | Automatically creates a dedicated namespace `ingress-nginx` to isolate controller components (RBAC, pods, configs). |
| `service.beta.kubernetes.io/aws-load-balancer-type="nlb"` | Instructs AWS to provision a modern **Network Load Balancer (NLB)** rather than a legacy Classic Load Balancer (CLB), providing lower latency and higher throughput. |
| `service.beta.kubernetes.io/aws-load-balancer-scheme="internet-facing"` | Provisions the NLB in your cluster's public subnets (tagged with `kubernetes.io/role/elb = 1`) so that traffic from the public internet can reach your application. |

---

### What Resources Get Created in Your Cluster

1. **IngressClass (`nginx`)**:
   - Defines `nginx` as an available ingress controller in your cluster. This allows any Ingress resource specifying `spec.ingressClassName: nginx` (like your `kubedefs/appingress.yaml`) to be discovered and managed by this controller.
2. **Controller Deployment & Pods**:
   - Runs the NGINX reverse-proxy process. It monitors the Kubernetes API for `Ingress` resources, dynamically updates its internal `nginx.conf`, and routes incoming HTTP/HTTPS traffic to the corresponding Kubernetes `Service` endpoints.
3. **LoadBalancer Service**:
   - Triggers AWS to create an external Load Balancer (NLB) with a public DNS hostname. Traffic entering ports 80 and 443 is forwarded to the NGINX controller pods on node ports.
4. **Validating Admission Webhook**:
   - Validates Ingress manifests when you run `kubectl apply` to reject invalid configurations before they can break the proxy.

---

### Verification Commands

1. **Check controller pod status:**
   ```bash
   kubectl get pods -n ingress-nginx
   ```
   *(Expected status: `Running` and ready `1/1`)*

2. **Retrieve the external Load Balancer address:**
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```
   The `EXTERNAL-IP` field will display the AWS NLB DNS name (e.g. `k8s-ingressn-...elb.us-east-1.amazonaws.com`).
