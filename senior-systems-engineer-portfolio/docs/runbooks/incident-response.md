# Incident Response Runbook

## 📞 Emergency Contacts

| Role | Contact | Phone | Email |
|------|---------|-------|-------|
| On-Call Engineer (Primary) | [Name] | +1-XXX-XXX-XXXX | oncall@company.com |
| On-Call Engineer (Secondary) | [Name] | +1-XXX-XXX-XXXX | oncall-backup@company.com |
| Security Team Lead | [Name] | +1-XXX-XXX-XXXX | security@company.com |
| Infrastructure Manager | [Name] | +1-XXX-XXX-XXXX | infra-mgr@company.com |
| Executive On-Call | [Name] | +1-XXX-XXX-XXXX | exec-oncall@company.com |

## 🚨 Severity Levels

### SEV-1 (Critical)
- **Definition**: Complete service outage affecting all users
- **Response Time**: Immediate (< 15 minutes)
- **Example**: AKS cluster down, complete network outage, security breach

### SEV-2 (High)
- **Definition**: Major functionality impaired, affecting multiple users
- **Response Time**: < 30 minutes
- **Example**: Single AKS node failure, Key Vault access issues, high error rates

### SEV-3 (Medium)
- **Definition**: Minor functionality impaired, workaround available
- **Response Time**: < 2 hours
- **Example**: Performance degradation, non-critical service offline

### SEV-4 (Low)
- **Definition**: Cosmetic issues, minimal impact
- **Response Time**: Next business day
- **Example**: Documentation errors, minor UI glitches

---

## 📋 Incident Response Process

### Phase 1: Detection & Triage (0-5 minutes)

#### 1.1 Alert Received
- **Source**: Azure Monitor, Prometheus, PagerDuty, Security alerts
- **Action**: Acknowledge alert within 5 minutes

#### 1.2 Initial Assessment
```bash
# Quick health check
kubectl get nodes
kubectl get pods --all-namespaces
az aks show --resource-group <rg-name> --name <aks-name> --query "powerState"

# Check Azure Service Health
az rest --method get --url "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01"
```

#### 1.3 Determine Severity
Use the severity matrix above to classify the incident

#### 1.4 Assemble Response Team
- SEV-1: Page all on-call engineers + management
- SEV-2: Page primary on-call + secondary
- SEV-3: Notify primary on-call (no page)

### Phase 2: Containment (5-15 minutes)

#### 2.1 Create Incident Ticket
```bash
# Create ServiceNow incident via API
python scripts/python/create_incident.py \
  --severity SEV-1 \
  --title "AKS cluster unresponsive" \
  --description "All pods in pending state"
```

#### 2.2 Establish Communication Channel
```bash
# Create dedicated Teams/Slack channel
# Format: incident-YYYY-MM-DD-HHMM
```

#### 2.3 Enable War Room
- **Video Bridge**: [Teams/Zoom Link]
- **Roles**: 
  - Incident Commander (IC)
  - Technical Lead
  - Communications Lead
  - Scribe (note taker)

#### 2.4 Containment Actions

**For SEV-1 Infrastructure Outage:**
```bash
# Redirect traffic to backup region (if available)
az network traffic-manager profile update \
  --resource-group prod-rg \
  --name prod-tm \
  --routing-method Priority

# Scale up redundant resources
kubectl scale deployment <app-name> --replicas=10

# Enable maintenance mode
kubectl apply -f kubernetes/maintenance-mode.yaml
```

**For SEV-1 Security Incident:**
```bash
# Isolate compromised resources
az network nsg rule create \
  --resource-group <rg-name> \
  --nsg-name <nsg-name> \
  --name deny-all-inbound \
  --priority 100 \
  --access Deny \
  --protocol '*' \
  --direction Inbound

# Rotate all secrets immediately
pwsh scripts/powershell/Rotate-Secrets.ps1 -Emergency

# Revoke suspicious service principals
az ad sp credential reset --id <sp-id>
```

### Phase 3: Investigation (15-60 minutes)

#### 3.1 Collect Diagnostic Data

**AKS Cluster:**
```bash
# Export cluster logs
kubectl cluster-info dump > cluster-dump.txt

# Get events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check node logs
kubectl logs -n kube-system <pod-name> --previous

# Describe problematic pods
kubectl describe pod <pod-name> -n <namespace>
```

**Azure Monitor:**
```kusto
// KQL Query - Last 1 hour errors
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where Category == "kube-apiserver"
| where log_s contains "error"
| project TimeGenerated, log_s
| order by TimeGenerated desc
```

**Prometheus Metrics:**
```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Check critical metrics
# - node_memory_MemAvailable_bytes
# - kube_pod_status_phase
# - container_cpu_usage_seconds_total
```

#### 3.2 Check Recent Changes
```bash
# Git changes in last 24 hours
git log --since="24 hours ago" --all --oneline

# Terraform state history
az storage blob list \
  --account-name <storage-account> \
  --container-name tfstate \
  --query "[?properties.lastModified > '$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)']"

# Azure Activity Log
az monitor activity-log list \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
  --resource-group <rg-name>
```

#### 3.3 Root Cause Analysis
Document findings in incident ticket:
- **Trigger**: What initiated the incident?
- **Root Cause**: Underlying issue
- **Contributing Factors**: What made it worse?

### Phase 4: Resolution (60+ minutes)

#### 4.1 Implement Fix

**Example: AKS Node Failure**
```bash
# Cordon and drain failed node
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Scale node pool
az aks nodepool scale \
  --resource-group <rg-name> \
  --cluster-name <aks-name> \
  --name <nodepool-name> \
  --node-count 5

# Verify pods rescheduled
kubectl get pods -o wide | grep <node-name>
```

**Example: Configuration Drift**
```bash
# Reapply Terraform configuration
cd terraform/environments/production
terraform plan -out=tfplan
terraform apply tfplan

# Rerun Ansible playbooks
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml
```

**Example: Secret Expiration**
```bash
# Rotate expired secrets
pwsh scripts/powershell/Rotate-Secrets.ps1 -SecretName "database-password"

# Update Key Vault references in AKS
kubectl rollout restart deployment/<app-name> -n <namespace>
```

#### 4.2 Validation
```bash
# Run smoke tests
bash scripts/bash/health-check.sh

# Verify metrics returned to normal
# - Check Grafana dashboards
# - Verify no active alerts
# - Confirm user impact resolved
```

### Phase 5: Recovery (Post-Fix)

#### 5.1 Disable Maintenance Mode
```bash
kubectl delete -f kubernetes/maintenance-mode.yaml
```

#### 5.2 Monitor Closely
- Watch metrics for 2 hours post-resolution
- Keep incident channel open for 1 hour
- Update stakeholders every 30 minutes

#### 5.3 Customer Communication
```markdown
**Incident Update - RESOLVED**

We have resolved the incident affecting [service/feature].

**Impact**: [Description of user impact]
**Duration**: [Start time] to [End time] (Total: X hours Y minutes)
**Root Cause**: [Brief explanation]
**Resolution**: [What we did to fix it]

We are continuing to monitor the situation closely.
```

### Phase 6: Post-Incident Review (Within 48 hours)

#### 6.1 Post-Incident Meeting
- **Attendees**: All responders + stakeholders
- **Duration**: 60 minutes
- **Agenda**:
  1. Timeline review
  2. What went well?
  3. What went wrong?
  4. Action items

#### 6.2 Post-Mortem Document
Template:
```markdown
# Post-Incident Review: [Incident Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Severity**: SEV-X
- **Duration**: X hours Y minutes
- **Services Affected**: [List]
- **Incident Commander**: [Name]

## Executive Summary
[2-3 sentence summary for leadership]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| 14:23 | Alert fired: High pod eviction rate |
| 14:25 | On-call engineer paged |
| 14:30 | Incident declared SEV-2 |
| ... | ... |

## Root Cause
[Detailed technical explanation]

## Impact
- **Users Affected**: X users (Y% of total)
- **Revenue Impact**: $Z (estimated)
- **SLO Burn**: X% of monthly error budget

## What Went Well
- ✅ Fast detection (2 minutes)
- ✅ Clear runbooks followed
- ✅ Good communication with stakeholders

## What Went Wrong
- ❌ Delayed root cause identification
- ❌ Missing monitoring for X metric
- ❌ Rollback took longer than expected

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Add monitoring for X metric | [Name] | YYYY-MM-DD | Open |
| Update runbook with Y procedure | [Name] | YYYY-MM-DD | Open |
| Implement automated rollback for Z | [Name] | YYYY-MM-DD | In Progress |
```

#### 6.3 Implement Preventive Measures
```bash
# Example: Add new alert rule
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: pod-eviction-alert
  namespace: monitoring
spec:
  groups:
    - name: pod-evictions
      rules:
        - alert: HighPodEvictionRate
          expr: rate(kube_pod_status_phase{phase="Failed"}[5m]) > 0.1
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High pod eviction rate detected"
            description: "More than 10% of pods are being evicted"
EOF
```

---

## 🛠️ Common Incident Scenarios

### Scenario 1: AKS Cluster Unresponsive

**Symptoms:**
- `kubectl` commands timeout
- Pods in Pending state
- High CPU/memory on nodes

**Investigation:**
```bash
# Check node status
kubectl get nodes -o wide

# Check resource utilization
kubectl top nodes
kubectl top pods --all-namespaces

# Check Azure health
az aks show --resource-group <rg> --name <aks> --query "powerState"
```

**Resolution:**
```bash
# Option 1: Scale up nodes
az aks nodepool scale --node-count 10 ...

# Option 2: Restart unresponsive nodes
az vmss restart --ids $(az vmss list -g MC_<rg>_<aks>_<location> --query "[].id" -o tsv)

# Option 3: Upgrade cluster (if version issue)
az aks upgrade --kubernetes-version <version> ...
```

### Scenario 2: Key Vault Access Denied

**Symptoms:**
- Applications can't retrieve secrets
- Error: "The user, group or application does not have secrets get permission"

**Investigation:**
```bash
# Check Key Vault access policies
az keyvault show --name <vault-name> --query "properties.accessPolicies"

# Check managed identity
kubectl get azureidentity -n <namespace>
kubectl logs -n <namespace> <pod-with-vault-access>
```

**Resolution:**
```bash
# Grant access to AKS managed identity
az keyvault set-policy \
  --name <vault-name> \
  --object-id <aks-identity-object-id> \
  --secret-permissions get list

# Restart pods to pick up new permissions
kubectl rollout restart deployment/<app> -n <namespace>
```

### Scenario 3: Security Breach Detected

**Symptoms:**
- Unusual outbound traffic
- Unexpected process running in containers
- Azure Security Center alert

**Immediate Actions:**
```bash
# 1. ISOLATE - Block all traffic to/from compromised resources
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# 2. PRESERVE EVIDENCE
kubectl get pod <suspicious-pod> -o yaml > evidence/pod-manifest.yaml
kubectl logs <suspicious-pod> > evidence/pod-logs.txt
kubectl exec <suspicious-pod> -- ps aux > evidence/processes.txt

# 3. ROTATE SECRETS IMMEDIATELY
pwsh scripts/powershell/Rotate-Secrets.ps1 -All -Emergency

# 4. REVIEW ACCESS LOGS
az monitor activity-log list --start-time <24h-ago> > evidence/azure-activity.json

# 5. NOTIFY SECURITY TEAM
# Send to security@company.com with:
# - Affected resources
# - Indicators of compromise
# - Actions taken
```

---

## 📊 Incident Metrics

Track these KPIs:
- **MTTD** (Mean Time To Detect): Alert to acknowledgment
- **MTTA** (Mean Time To Acknowledge): Alert to human response
- **MTTR** (Mean Time To Resolve): Alert to resolution
- **MTBF** (Mean Time Between Failures): Time between incidents

**Dashboard**: See Grafana dashboard "Incident Metrics"

---

## 📚 References

- [Azure Well-Architected Framework - Reliability](https://docs.microsoft.com/azure/architecture/framework/resiliency/)
- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)
- [Azure AKS Troubleshooting](https://docs.microsoft.com/azure/aks/troubleshooting)
- Internal Wiki: [link-to-internal-wiki]

---

**Document Version**: 1.0  
**Last Updated**: December 19, 2025  
**Owner**: Infrastructure Team
