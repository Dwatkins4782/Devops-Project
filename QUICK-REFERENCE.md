# Quick Reference Guide

## **Lens Setup (Already Installed)**

### Launch Lens
1. Open **Lens** from Start Menu
2. Click **"+"** → **"Add from kubeconfig"**
3. Select: `C:\Users\davon\.kube\devops-cluster-config`
4. Click **"Add cluster"**

### What You'll See in Lens

#### **Workloads**
- **Pods**: Running containers
  - Right-click → **Logs** to view pod logs
  - Right-click → **Shell** to access pod terminal
- **Deployments**: Application deployments
- **StatefulSets**: Stateful applications
- **Jobs**: One-time tasks

#### **Network**
- **Services**: Network endpoints
  - Click service → **Forward Port** for easy access
- **Ingresses**: External routing

#### **Config & Storage**
- **ConfigMaps**: Configuration data
- **Secrets**: Sensitive data (encoded)
- **PVCs**: Persistent storage claims

#### **Custom Resources**
- **ServiceMonitors**: Prometheus scrape configs
- Look for `monitoring.coreos.com/v1` resources

### Lens Pro Tips

**View Pod Logs:**
- Workloads → Pods → Right-click pod → **Logs**
- Check **Follow** to stream logs in real-time

**Port Forward:**
- Network → Services → Click service → **Forward** button
- Auto-assigns local port or choose custom

**Resource Usage:**
- Cluster → **Metrics** tab shows CPU/Memory graphs
- Install **Metrics Server** if not available:
  ```powershell
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  ```

**Terminal Access:**
- Workloads → Pods → Right-click → **Shell**
- Opens terminal inside container

**Edit Resources:**
- Right-click any resource → **Edit**
- Live YAML editor with validation

---

## **Creating New Projects**

### **Option 1: Using the Generator Script**

```powershell
# Python project
.\New-DevOpsProject.ps1 -ProjectName "my-api" -Language python

# Node.js project
.\New-DevOpsProject.ps1 -ProjectName "my-service" -Language nodejs -TargetPath "C:\Projects"

# Java project
.\New-DevOpsProject.ps1 -ProjectName "order-service" -Language java
```

This creates a complete project structure with:
- ✅ Application code template
- ✅ Dockerfile
- ✅ Helm chart
- ✅ Terraform config
- ✅ Automation scripts
- ✅ README

### **Option 2: Manual Copy**

```powershell
# Copy entire project
Copy-Item -Recurse C:\Devops-Project C:\MyNewProject

# Navigate and customize
cd C:\MyNewProject
```

Then update:
- `helm/app/Chart.yaml` → Change `name`
- `helm/app/values.yaml` → Change `image.repository`
- `terraform/main.tf` → Change cluster `name`
- `app/*` → Your application code

---

## **Common Tasks**

### **Deploy New Application**

```powershell
# 1. Generate project
.\New-DevOpsProject.ps1 -ProjectName "my-app" -Language python

# 2. Navigate to project
cd C:\my-app

# 3. (Optional) Customize app code
# Edit app\app.py

# 4. Setup cluster
cd scripts
.\setup.ps1

# 5. Build image
.\build.ps1

# 6. Deploy app
.\deploy.ps1

# 7. View in Lens
# Open Lens → Add cluster → C:\Users\davon\.kube\my-app-cluster-config
```

### **Update Existing Application**

```powershell
# 1. Modify code
# Edit app/app.py

# 2. Rebuild
cd scripts
.\build.ps1

# 3. Redeploy
.\deploy.ps1

# 4. Verify in Lens
# Pods should show new timestamp
```

### **Scale Application**

```powershell
# Using kubectl
kubectl scale deployment my-app -n production --replicas=5

# Or using Lens
# Workloads → Deployments → Right-click → Scale
```

### **View Logs**

**Option 1: Lens**
- Workloads → Pods → Right-click → Logs

**Option 2: kubectl**
```powershell
kubectl logs -n production -l app.kubernetes.io/name=my-app -f
```

### **Access Application**

**Option 1: Lens**
- Network → Services → Click service → Forward (assigns random port)

**Option 2: kubectl**
```powershell
kubectl port-forward -n production svc/my-app 8080:80
```

---

## **Multi-Service Projects**

For microservices architecture:

```powershell
# Create multiple services
.\New-DevOpsProject.ps1 -ProjectName "api-gateway" -Language nodejs
.\New-DevOpsProject.ps1 -ProjectName "user-service" -Language python
.\New-DevOpsProject.ps1 -ProjectName "order-service" -Language java

# Deploy all to same cluster
cd C:\api-gateway\scripts
.\setup.ps1

cd C:\user-service\scripts
.\build.ps1
.\deploy.ps1

cd C:\order-service\scripts
.\build.ps1
.\deploy.ps1

# View all in Lens
# Single cluster, multiple namespaces
```

---

## **Kubernetes Commands Cheat Sheet**

### **Cluster Info**
```powershell
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### **Workloads**
```powershell
# Pods
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> -f

# Deployments
kubectl get deployments -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout restart deployment/<name> -n <namespace>
```

### **Services**
```powershell
kubectl get services -n <namespace>
kubectl describe service <name> -n <namespace>
kubectl port-forward svc/<name> 8080:80 -n <namespace>
```

### **Debugging**
```powershell
# Shell into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Copy files from pod
kubectl cp <namespace>/<pod-name>:/path/to/file ./local-file

# Events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## **Helm Commands**

```powershell
# List releases
helm list -A

# Get values
helm get values <release-name> -n <namespace>

# Upgrade with new values
helm upgrade <release-name> ./helm/chart -n <namespace> --set key=value

# Rollback
helm rollback <release-name> -n <namespace>

# Uninstall
helm uninstall <release-name> -n <namespace>
```

---

## **Lens Keyboard Shortcuts**

- `Ctrl + K` - Command palette
- `Ctrl + Shift + L` - View logs
- `Ctrl + T` - Terminal
- `Ctrl + F` - Search
- `F5` - Refresh

---

## **Troubleshooting**

### **Pod Not Starting**

1. **Check pod status:**
   ```powershell
   kubectl get pods -n <namespace>
   ```

2. **Describe pod:**
   ```powershell
   kubectl describe pod <pod-name> -n <namespace>
   ```
   Look for: `Events` section

3. **Check logs:**
   ```powershell
   kubectl logs <pod-name> -n <namespace>
   ```

4. **Common issues:**
   - Image pull error → Image not in cluster
   - CrashLoopBackOff → Application failing, check logs
   - Pending → Resource constraints or scheduling issues

### **Service Not Accessible**

1. **Check service:**
   ```powershell
   kubectl get svc -n <namespace>
   kubectl get endpoints -n <namespace>
   ```

2. **Verify pods are running:**
   ```powershell
   kubectl get pods -n <namespace>
   ```

3. **Test from inside cluster:**
   ```powershell
   kubectl run test --image=busybox -it --rm -- wget -O- http://service-name:80
   ```

### **Metrics Not Showing in Grafana**

1. **Check ServiceMonitor:**
   ```powershell
   kubectl get servicemonitor -n <namespace>
   ```

2. **Check Prometheus targets:**
   ```powershell
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```
   Visit: http://localhost:9090/targets

3. **Generate traffic:**
   - Must make requests to app first
   - Metrics appear after 30-60 seconds

---

## **Cleanup**

### **Delete Application**
```powershell
helm uninstall <app-name> -n <namespace>
kubectl delete namespace <namespace>
```

### **Delete Cluster**
```powershell
cd terraform
terraform destroy -auto-approve
```

### **Remove from Lens**
- Right-click cluster → **Remove**

---

## **Next Steps**

1. ✅ **Launch Lens** and explore your current cluster
2. ✅ **Create a new project** using the generator
3. ✅ **Deploy to the cluster**
4. ✅ **Monitor in Lens** and **Grafana**
5. ✅ **Scale, update, and manage** through Lens UI

You're now equipped with:
- 🎨 **Lens** - Visual Kubernetes management
- 🚀 **Project Generator** - Create new projects in seconds
- 📚 **Template Guide** - Adapt to any language/framework
- 🔧 **Automation Scripts** - One-command deployments

Happy coding! 🎉
