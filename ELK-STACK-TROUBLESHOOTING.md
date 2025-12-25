# ELK Stack Implementation - Issue Log & Troubleshooting Guide

**Project**: DevOps Challenge - ELK Stack Integration  
**Date**: December 25, 2025  
**Status**: ✅ Resolved

---

## Issues Encountered & Fixes

### Issue #1: PowerShell String Termination Errors in Makefile
**Severity**: High  
**Component**: Makefile (Windows)

**Problem**:
```
The string is missing the terminator: ".
ParserError: TerminatorExpectedAtEndOfString
```

**Root Cause**:
- Emoji characters (🔨, 📝, ✅) in PowerShell strings causing parsing errors
- Long single-line commands with multiple PowerShell statements separated by semicolons
- Incorrect use of `2>nul` instead of `2>$null` for error redirection
- Bash-style `||` operator not supported in PowerShell

**Fix Applied**:
```makefile
# BEFORE (Broken)
@Write-Host "🔨 Building..." -ForegroundColor Cyan; docker build...

# AFTER (Fixed)
@powershell -Command "Write-Host 'Building...' -ForegroundColor Cyan"
@docker build -t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) ./app
```

**Changes Made**:
- Removed emojis from PowerShell strings
- Split long command chains into separate lines
- Used explicit `powershell -Command` wrapper
- Changed error redirection to proper PowerShell syntax

**Files Modified**:
- `Makefile` (lines 38-42, 56-62, 92-98)

---

### Issue #2: Docker Desktop Not Running
**Severity**: Critical  
**Component**: Infrastructure

**Problem**:
```
failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine
The system cannot find the file specified.
```

**Root Cause**:
Docker Desktop service was not started on Windows host.

**Fix Applied**:
```powershell
# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for initialization
Start-Sleep -Seconds 15

# Verify
docker ps
```

**Prevention**:
- Add Docker status check to Makefile `setup` target
- Create pre-flight validation script

**Files Modified**:
- N/A (operational fix)

---

### Issue #3: Helm Values YAML Parsing Error
**Severity**: High  
**Component**: Helm Chart Configuration

**Problem**:
```
error calling include:
nil pointer evaluating interface {}.yml
```

**Root Cause**:
YAML keys with dots (`.`) in nested structures cause parsing issues:
```yaml
# BROKEN
config:
  logstash.yml: |
    content...
  pipeline.conf: |
    content...
```

**Fix Applied**:
```yaml
# FIXED
config:
  logstashYml: |
    content...
  pipelineConf: |
    content...
```

**Template Update**:
```yaml
# logstash-configmap.yaml
data:
  logstash.yml: |
    {{- .Values.logstash.config.logstashYml | nindent 4 }}
  pipeline.conf: |
    {{- .Values.logstash.config.pipelineConf | nindent 4 }}
```

**Files Modified**:
- `helm/elk/values.yaml` (lines 49-51)
- `helm/elk/templates/logstash-configmap.yaml` (lines 11-14)

---

### Issue #4: Application Container Crashes
**Severity**: High  
**Component**: Application Deployment

**Problem**:
```
[CRITICAL] WORKER TIMEOUT (pid:11)
[ERROR] Worker (pid:11) was sent SIGKILL! Perhaps out of memory?
```

**Root Cause**:
- Missing environment variables (`LOGSTASH_HOST`, `LOGSTASH_PORT`)
- Python application attempting to connect to Logstash without proper configuration
- Logstash handler initialization blocking application startup

**Fix Applied**:
1. Updated Helm deployment template with environment variables:
```yaml
# helm/app/templates/deployment.yaml
env:
  - name: LOGSTASH_HOST
    value: "logstash"
  - name: LOGSTASH_PORT
    value: "5000"
  - name: APP_VERSION
    value: "{{ .Chart.AppVersion }}"
```

2. Updated application with fallback logic:
```python
# app/app.py
try:
    from logstash_async.handler import AsynchronousLogstashHandler
    logstash_handler = AsynchronousLogstashHandler(...)
    logger.addHandler(logstash_handler)
except (ImportError, Exception) as e:
    logger.warning(f"Logstash handler not available: {e}")
```

3. Redeployed application:
```bash
helm upgrade devops-app ./helm/app --namespace app --reuse-values
```

**Files Modified**:
- `helm/app/templates/deployment.yaml` (added env section)
- `app/app.py` (added error handling)

---

### Issue #5: Port Forward Connection Refused
**Severity**: Medium  
**Component**: Kubernetes Networking

**Problem**:
```
Hmmm… can't reach this page
localhost refused to connect
```

**Root Cause**:
Port forwarding not established or background job terminated prematurely.

**Fix Applied**:
```powershell
# Start port-forward as background job
Start-Job -ScriptBlock { 
    kubectl port-forward -n monitoring svc/kibana 5601:5601 
}

# Or use dedicated terminal window
kubectl port-forward -n monitoring svc/kibana 5601:5601
```

**Verification**:
```powershell
curl http://localhost:5601/api/status -UseBasicParsing
# Should return: StatusCode: 200
```

**Files Modified**:
- `Makefile` (fixed `port-forward-kibana` target)

---

## Future Reference: Common Issues & Solutions

### Issue: Elasticsearch Won't Start (Memory)

**Symptoms**:
```
Elasticsearch pod stuck in CrashLoopBackOff
"max virtual memory areas vm.max_map_count [65530] is too low"
```

**Solution**:
```bash
# For Docker Desktop on Windows (WSL2)
wsl -d docker-desktop
sysctl -w vm.max_map_count=262144
exit

# For Kind clusters, increase Docker memory to 4GB+
```

**Files to Check**:
- `helm/elk/values.yaml` (elasticsearch.resources)

---

### Issue: No Logs Appearing in Kibana

**Symptoms**:
- Kibana Discover shows "No results found"
- Index pattern created but no data

**Troubleshooting Steps**:

1. **Check Elasticsearch indices**:
```bash
kubectl exec -it deployment/elk-stack-elasticsearch -n monitoring -- \
  curl http://localhost:9200/_cat/indices?v
```

2. **Verify Logstash is receiving data**:
```bash
kubectl logs -n monitoring deployment/elk-stack-logstash --tail=50
# Look for: "Pipeline started successfully"
```

3. **Check application logs**:
```bash
kubectl logs -n app deployment/devops-app --tail=50
# Should see: "Logstash handler configured: logstash:5000"
```

4. **Verify Filebeat is running**:
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/component=filebeat
kubectl logs -n monitoring daemonset/elk-stack-filebeat
```

5. **Test Logstash connectivity**:
```bash
kubectl run test --rm -i --tty --image=busybox --restart=Never -- \
  nc -zv logstash.monitoring.svc.cluster.local 5000
```

**Common Fixes**:
- Refresh index pattern in Kibana: Management → Index Patterns → Refresh
- Adjust time range in Kibana Discover (top-right corner)
- Check network policies aren't blocking traffic
- Verify service endpoints: `kubectl get endpoints -n monitoring`

---

### Issue: Filebeat Permission Denied

**Symptoms**:
```
ERROR [reader_docker_json] Failed to open /var/log/containers/*.log: 
Permission denied
```

**Solution**:
Filebeat DaemonSet already configured with:
```yaml
securityContext:
  runAsUser: 0
  privileged: true
```

If still failing, check SELinux/AppArmor policies on cluster nodes.

---

### Issue: Kibana "Unable to connect to Elasticsearch"

**Symptoms**:
Kibana UI shows red banner: "Unable to connect to Elasticsearch"

**Troubleshooting**:
```bash
# 1. Check Elasticsearch is running
kubectl get pods -n monitoring -l app.kubernetes.io/component=elasticsearch

# 2. Check Kibana can reach Elasticsearch
kubectl exec -it deployment/elk-stack-kibana -n monitoring -- \
  curl http://elasticsearch:9200/_cluster/health

# 3. Check Kibana environment variables
kubectl get deployment elk-stack-kibana -n monitoring -o yaml | grep ELASTICSEARCH
```

**Solution**:
- Ensure `ELASTICSEARCH_HOSTS` env var is correct: `http://elasticsearch:9200`
- Verify Elasticsearch service exists: `kubectl get svc elasticsearch -n monitoring`
- Restart Kibana: `kubectl rollout restart deployment/elk-stack-kibana -n monitoring`

---

### Issue: High Memory Usage / OOMKilled

**Symptoms**:
```
Elasticsearch/Logstash pods keep restarting
Status: OOMKilled
```

**Solution**:
Adjust resource limits in `helm/elk/values.yaml`:

```yaml
elasticsearch:
  resources:
    requests:
      memory: "4Gi"  # Increase from 2Gi
    limits:
      memory: "6Gi"  # Increase from 4Gi
  env:
    - name: ES_JAVA_OPTS
      value: "-Xms2g -Xmx2g"  # Heap should be 50% of memory limit
```

Also increase Docker Desktop memory allocation:
- Docker Desktop → Settings → Resources → Memory → 8GB+

---

### Issue: Slow Query Performance

**Symptoms**:
- Kibana searches taking >10 seconds
- Elasticsearch response times high

**Solutions**:

1. **Check cluster health**:
```bash
kubectl exec deployment/elk-stack-elasticsearch -n monitoring -- \
  curl http://localhost:9200/_cluster/health?pretty
```

2. **Check shard allocation**:
```bash
kubectl exec deployment/elk-stack-elasticsearch -n monitoring -- \
  curl http://localhost:9200/_cat/shards?v
```

3. **Optimize index settings** (for production):
```bash
# Reduce number of replicas for single-node setup
PUT /logs-*/_settings
{
  "number_of_replicas": 0
}

# Enable index lifecycle management
# Use warm/cold tiers for older data
```

4. **Scale Elasticsearch**:
```yaml
# helm/elk/values.yaml
elasticsearch:
  replicas: 3  # Increase from 1
```

---

### Issue: Certificate/TLS Errors (Production)

**Symptoms**:
```
SSL certificate problem: unable to get local issuer certificate
```

**Solution** (when enabling X-Pack Security):

1. **Generate certificates**:
```bash
kubectl exec deployment/elk-stack-elasticsearch -n monitoring -- \
  /usr/share/elasticsearch/bin/elasticsearch-certutil ca --pem

kubectl exec deployment/elk-stack-elasticsearch -n monitoring -- \
  /usr/share/elasticsearch/bin/elasticsearch-certutil cert \
    --ca elastic-stack-ca.p12 --pem
```

2. **Create Kubernetes secrets**:
```bash
kubectl create secret generic elk-certs \
  --from-file=ca.crt=ca/ca.crt \
  --from-file=elasticsearch.crt=elasticsearch/elasticsearch.crt \
  --from-file=elasticsearch.key=elasticsearch/elasticsearch.key \
  -n monitoring
```

3. **Update values.yaml**:
```yaml
elasticsearch:
  env:
    - name: xpack.security.enabled
      value: "true"
    - name: xpack.security.transport.ssl.enabled
      value: "true"
```

---

## Validation Checklist

Use this checklist to verify ELK Stack is working correctly:

- [ ] **Docker Desktop is running**
  ```bash
  docker ps
  ```

- [ ] **Kubernetes cluster is accessible**
  ```bash
  kubectl cluster-info
  ```

- [ ] **All ELK pods are running**
  ```bash
  kubectl get pods -n monitoring
  # All should show STATUS: Running, READY: 1/1
  ```

- [ ] **Elasticsearch is healthy**
  ```bash
  kubectl exec deployment/elk-stack-elasticsearch -n monitoring -- \
    curl http://localhost:9200/_cluster/health
  # Should return: "status":"green" or "yellow"
  ```

- [ ] **Logstash is processing logs**
  ```bash
  kubectl logs -n monitoring deployment/elk-stack-logstash --tail=20
  # Should see successful pipeline messages
  ```

- [ ] **Kibana is accessible**
  ```bash
  kubectl port-forward svc/kibana 5601:5601 -n monitoring
  # Open: http://localhost:5601
  ```

- [ ] **Indices are being created**
  ```bash
  curl http://localhost:9200/_cat/indices?v
  # Should see: logs-YYYY.MM.DD
  ```

- [ ] **Application is sending logs**
  ```bash
  kubectl logs -n app deployment/devops-app | grep -i logstash
  ```

- [ ] **Filebeat is collecting logs**
  ```bash
  kubectl logs -n monitoring daemonset/elk-stack-filebeat --tail=10
  ```

- [ ] **Index pattern exists in Kibana**
  - Go to Management → Index Patterns
  - Verify `logs-*` exists

- [ ] **Logs are visible in Discover**
  - Go to Analytics → Discover
  - Select `logs-*` index pattern
  - Adjust time range if needed

---

## Quick Commands Reference

### Deploy ELK Stack
```powershell
# Full deployment
make elk

# Or manually
helm install elk-stack ./helm/elk --namespace monitoring --create-namespace

# With custom values
helm install elk-stack ./helm/elk -f custom-values.yaml -n monitoring
```

### Access Kibana
```powershell
# Port forward
kubectl port-forward svc/kibana 5601:5601 -n monitoring

# Or use Makefile
make port-forward-kibana

# Then open: http://localhost:5601
```

### View Logs
```bash
# Elasticsearch logs
kubectl logs -n monitoring deployment/elk-stack-elasticsearch -f

# Logstash logs
kubectl logs -n monitoring deployment/elk-stack-logstash -f

# Kibana logs
kubectl logs -n monitoring deployment/elk-stack-kibana -f

# Filebeat logs
kubectl logs -n monitoring daemonset/elk-stack-filebeat -f

# Application logs
kubectl logs -n app deployment/devops-app -f
```

### Restart Components
```bash
kubectl rollout restart deployment/elk-stack-elasticsearch -n monitoring
kubectl rollout restart deployment/elk-stack-logstash -n monitoring
kubectl rollout restart deployment/elk-stack-kibana -n monitoring
kubectl rollout restart daemonset/elk-stack-filebeat -n monitoring
```

### Uninstall
```powershell
# Using Makefile
make elk-uninstall

# Or manually
helm uninstall elk-stack -n monitoring
```

### Local Testing (Docker Compose)
```powershell
# Start
make elk-local
# or
docker-compose -f docker-compose.elk.yml up -d

# Stop
make elk-stop
# or
docker-compose -f docker-compose.elk.yml down

# Reset (WARNING: deletes data)
docker-compose -f docker-compose.elk.yml down -v
```

---

## Performance Tuning Tips

### For Development/Testing
```yaml
# helm/elk/values.yaml
elasticsearch:
  replicas: 1
  resources:
    requests:
      memory: "2Gi"
  persistence:
    size: 10Gi

logstash:
  replicas: 1
  
filebeat:
  enabled: true  # Optional for dev
```

### For Production
```yaml
elasticsearch:
  replicas: 3
  resources:
    requests:
      memory: "4Gi"
      cpu: "2000m"
  persistence:
    size: 100Gi
    storageClass: "fast-ssd"

logstash:
  replicas: 2
  
filebeat:
  enabled: true
  
kibana:
  replicas: 2
```

---

## Security Best Practices

### Enable X-Pack Security (Production)
```yaml
elasticsearch:
  env:
    - name: xpack.security.enabled
      value: "true"
```

### Set Passwords
```bash
kubectl exec -it deployment/elk-stack-elasticsearch -n monitoring -- \
  /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
```

### Use RBAC
Filebeat service account already configured with minimal permissions:
- `get`, `watch`, `list` on: pods, nodes, namespaces

### Network Policies
Consider implementing network policies to restrict traffic:
- Only allow application pods to reach Logstash
- Only allow Kibana to reach Elasticsearch
- Deny public internet access to Elasticsearch

---

## Monitoring ELK Stack Itself

### Enable Metricbeat
Add Metricbeat to monitor ELK stack health:
```bash
helm repo add elastic https://helm.elastic.co
helm install metricbeat elastic/metricbeat -n monitoring
```

### Key Metrics to Watch
- Elasticsearch JVM heap usage (should be <75%)
- Disk usage (set up alerts at 80%)
- Query latency
- Indexing rate
- Filebeat harvest rate

### Grafana Dashboards
Import pre-built Elasticsearch dashboards:
- Dashboard ID: 266 (Elasticsearch Overview)
- Dashboard ID: 2322 (Logstash Stats)

---

## Summary

**Total Issues Resolved**: 5  
**Files Created**: 20+  
**Files Modified**: 5  
**Deployment Status**: ✅ Successful  

**Key Achievements**:
- Full ELK Stack deployed in Kubernetes
- Filebeat DaemonSet collecting all pod logs
- Application integrated with Logstash for structured logging
- Makefile commands for easy deployment
- Docker Compose for local testing
- Comprehensive documentation

**Tested and Verified**:
- ✅ Elasticsearch cluster healthy
- ✅ Logstash processing pipeline active
- ✅ Kibana UI accessible
- ✅ Filebeat collecting logs from all pods
- ✅ Application sending structured logs
- ✅ Logs visible in Kibana Discover

---

## Contact & Support

For issues or questions:
1. Check this troubleshooting guide
2. Review [ELK-STACK-README.md](ELK-STACK-README.md)
3. Check Elasticsearch/Elastic.co documentation
4. Review Kubernetes logs: `kubectl logs -n monitoring <pod-name>`

**Useful Resources**:
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Filebeat Documentation](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
