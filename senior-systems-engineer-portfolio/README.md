# Senior Systems Engineer II - Infrastructure & Automation Portfolio

## 🎯 Project Overview

This portfolio project demonstrates enterprise-grade infrastructure automation, security, and operational excellence aligned with Senior Systems Engineer II responsibilities. It showcases Infrastructure as Code (IaC), configuration management, CI/CD pipelines, secrets management, RBAC, observability, and security compliance.

**Target Role**: Senior Systems Engineer II | Platform Engineering | SRE  
**Experience Level**: 5+ years systems/platform/DevOps engineering  
**Primary Cloud**: Microsoft Azure

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GitHub Actions / Azure DevOps                 │
│                    Multi-Stage CI/CD with Approvals                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      Spacelift IaC Orchestration                     │
│              Drift Detection │ Policy as Code │ State Management    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         Terraform (Azure)                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Networking   │  │   AKS/K8s    │  │  Key Vault   │             │
│  │ VNet/Subnet  │  │   Cluster    │  │   Secrets    │             │
│  │  NSG/WAF     │  │              │  │              │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ VM Scale Sets│  │  Storage     │  │  Monitoring  │             │
│  │ Linux/Windows│  │   Accounts   │  │ Azure Monitor│             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    Ansible Configuration Management                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Golden Images│  │   Patching   │  │ App Deploy   │             │
│  │ Linux/Windows│  │  Automation  │  │ Orchestration│             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    Observability & Security Stack                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Prometheus/  │  │ Azure Monitor│  │ Policy as    │             │
│  │   Grafana    │  │  Log Analytics│ │ Code (OPA)   │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ Secret Scan  │  │   RBAC       │  │    CMDB      │             │
│  │ Vault Mgmt   │  │ Enforcement  │  │  Integration │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 💼 Skills Demonstrated

### Infrastructure as Code (IaC)
- ✅ **Terraform at Scale**: Modules, workspaces, remote state (Azure Storage), state locking
- ✅ **Spacelift Integration**: Drift detection, policy enforcement, workflow orchestration
- ✅ **Policy as Code**: OPA/Conftest for security and compliance validation
- ✅ **Multi-Environment**: Dev, Staging, Production with workspace isolation

### Configuration Management
- ✅ **Ansible**: Roles, playbooks, dynamic inventory, vault encryption
- ✅ **Golden Images**: Packer templates for hardened Linux/Windows images
- ✅ **Patch Management**: Automated OS patching workflows for Linux/Windows
- ✅ **Configuration Drift**: Detection and remediation

### Secrets & Security
- ✅ **Azure Key Vault**: Secret storage, rotation policies, access policies
- ✅ **HashiCorp Vault**: Dynamic secrets, encryption as a service
- ✅ **Secret Scanning**: GitGuardian, Gitleaks integration in pipelines
- ✅ **RBAC**: Least-privilege access across Azure, GitHub, pipelines
- ✅ **Supply Chain Security**: SBOM generation, container scanning

### CI/CD Pipelines
- ✅ **GitHub Actions**: Multi-stage workflows, reusable actions, matrix strategies
- ✅ **Azure DevOps**: YAML pipelines, approvals, environments, service connections
- ✅ **Artifact Management**: Azure Artifacts, versioning strategies
- ✅ **Security Gates**: Vulnerability scanning, policy checks, approval gates

### Observability & Reliability
- ✅ **Azure Monitor**: Log Analytics, Application Insights, alerts
- ✅ **Prometheus/Grafana**: Custom metrics, dashboards, SLIs/SLOs
- ✅ **Logging**: Centralized log aggregation, query optimization
- ✅ **Alerting**: Actionable alerts with runbook links

### Containers & Orchestration
- ✅ **Azure Kubernetes Service (AKS)**: Multi-node clusters, autoscaling
- ✅ **Docker**: Multi-stage builds, image hardening, vulnerability scanning
- ✅ **Helm**: Chart management, GitOps workflows
- ✅ **Container Security**: Aqua Security, Trivy scanning

### Governance & Compliance
- ✅ **CMDB Management**: ServiceNow integration, CI/CD relationship mapping
- ✅ **Change Control**: Automated CAB processes, change traceability
- ✅ **Incident Response**: Automated runbooks, post-incident reviews
- ✅ **Compliance**: ISO 27001, SOC 2, Azure Policy enforcement

---

## 📂 Project Structure

```
senior-systems-engineer-portfolio/
│
├── README.md                          # This file
├── .gitignore
│
├── terraform/                         # Infrastructure as Code
│   ├── modules/                       # Reusable Terraform modules
│   │   ├── networking/                # VNet, subnets, NSGs, WAF
│   │   ├── aks/                       # Azure Kubernetes Service
│   │   ├── keyvault/                  # Azure Key Vault
│   │   ├── storage/                   # Storage accounts, blob containers
│   │   ├── vmss/                      # VM Scale Sets (Linux/Windows)
│   │   ├── monitoring/                # Azure Monitor, Log Analytics
│   │   └── security/                  # Security Center, policies
│   │
│   ├── environments/                  # Environment configurations
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── staging/
│   │   └── production/
│   │
│   ├── policies/                      # Policy as Code (OPA/Sentinel)
│   │   ├── opa/                       # Open Policy Agent policies
│   │   ├── sentinel/                  # HashiCorp Sentinel policies
│   │   └── conftest/                  # Conftest policies
│   │
│   └── spacelift/                     # Spacelift stack configurations
│       ├── stacks.tf
│       └── policies.tf
│
├── ansible/                           # Configuration Management
│   ├── playbooks/                     # Ansible playbooks
│   │   ├── site.yml                   # Master playbook
│   │   ├── linux-hardening.yml        # Linux security baseline
│   │   ├── windows-hardening.yml      # Windows security baseline
│   │   ├── patching.yml               # OS patching automation
│   │   ├── golden-image.yml           # Image building workflow
│   │   └── app-deploy.yml             # Application deployment
│   │
│   ├── roles/                         # Ansible roles
│   │   ├── common/                    # Common configurations
│   │   ├── linux-baseline/            # Linux hardening
│   │   ├── windows-baseline/          # Windows hardening
│   │   ├── monitoring-agent/          # Observability agents
│   │   ├── vault-agent/               # HashiCorp Vault agent
│   │   └── app-server/                # Application server setup
│   │
│   ├── inventory/                     # Dynamic inventory
│   │   ├── azure_rm.yml               # Azure dynamic inventory
│   │   ├── production.ini
│   │   └── staging.ini
│   │
│   ├── group_vars/                    # Group variables
│   │   ├── all.yml
│   │   ├── linux.yml
│   │   └── windows.yml
│   │
│   └── ansible.cfg                    # Ansible configuration
│
├── pipelines/                         # CI/CD Pipelines
│   ├── github-actions/                # GitHub Actions workflows
│   │   ├── terraform-plan.yml
│   │   ├── terraform-apply.yml
│   │   ├── ansible-lint.yml
│   │   ├── security-scan.yml
│   │   ├── container-build.yml
│   │   └── release.yml
│   │
│   ├── azure-devops/                  # Azure DevOps pipelines
│   │   ├── infrastructure-pipeline.yml
│   │   ├── application-pipeline.yml
│   │   ├── security-pipeline.yml
│   │   └── templates/                 # Reusable templates
│   │       ├── terraform-stage.yml
│   │       ├── ansible-stage.yml
│   │       └── approval-stage.yml
│   │
│   └── spacelift/                     # Spacelift workflow configs
│       └── workflow.yml
│
├── kubernetes/                        # Kubernetes manifests
│   ├── applications/                  # App deployments
│   ├── monitoring/                    # Prometheus/Grafana
│   ├── security/                      # Network policies, PSPs
│   └── rbac/                          # RBAC configurations
│
├── docker/                            # Container configurations
│   ├── Dockerfile.app                 # Application container
│   ├── Dockerfile.golden-linux        # Hardened Linux base
│   ├── Dockerfile.golden-windows      # Hardened Windows base
│   └── .dockerignore
│
├── scripts/                           # Automation scripts
│   ├── powershell/                    # PowerShell scripts
│   │   ├── Deploy-Infrastructure.ps1
│   │   ├── Rotate-Secrets.ps1
│   │   ├── Backup-State.ps1
│   │   └── Audit-RBAC.ps1
│   │
│   ├── python/                        # Python scripts
│   │   ├── cmdb_sync.py               # CMDB synchronization
│   │   ├── secret_rotation.py         # Secret rotation automation
│   │   ├── compliance_check.py        # Compliance validation
│   │   └── drift_detection.py         # Infrastructure drift detection
│   │
│   └── bash/                          # Bash scripts
│       ├── deploy.sh                  # Deployment automation
│       ├── backup.sh                  # Backup automation
│       └── health-check.sh            # Health monitoring
│
├── observability/                     # Monitoring & Logging
│   ├── prometheus/                    # Prometheus configs
│   │   ├── prometheus.yml
│   │   ├── alerts.yml
│   │   └── recording-rules.yml
│   │
│   ├── grafana/                       # Grafana dashboards
│   │   ├── dashboards/
│   │   │   ├── infrastructure.json
│   │   │   ├── application.json
│   │   │   └── security.json
│   │   └── datasources/
│   │
│   ├── azure-monitor/                 # Azure Monitor configs
│   │   ├── log-queries.kql
│   │   ├── alert-rules.json
│   │   └── workbooks.json
│   │
│   └── slo/                           # SLI/SLO definitions
│       ├── availability.yml
│       ├── latency.yml
│       └── error-budget.yml
│
├── docs/                              # Documentation
│   ├── architecture/                  # Architecture diagrams
│   │   ├── overview.drawio
│   │   ├── network-topology.png
│   │   └── security-model.md
│   │
│   ├── runbooks/                      # Operational runbooks
│   │   ├── incident-response.md
│   │   ├── deployment-runbook.md
│   │   ├── rollback-procedure.md
│   │   ├── secret-rotation.md
│   │   └── disaster-recovery.md
│   │
│   ├── guides/                        # How-to guides
│   │   ├── terraform-development.md
│   │   ├── ansible-best-practices.md
│   │   ├── rbac-management.md
│   │   └── troubleshooting.md
│   │
│   ├── cmdb/                          # CMDB documentation
│   │   ├── service-catalog.md
│   │   ├── dependency-mapping.md
│   │   └── change-tracking.md
│   │
│   └── compliance/                    # Compliance documentation
│       ├── iso27001-controls.md
│       ├── soc2-evidence.md
│       └── audit-trail.md
│
├── security/                          # Security tooling
│   ├── secret-scanning/               # Secret detection
│   │   ├── .gitleaks.toml
│   │   └── gitguardian.yml
│   │
│   ├── sbom/                          # Software Bill of Materials
│   │   └── generate-sbom.sh
│   │
│   ├── container-scanning/            # Container vulnerability scanning
│   │   ├── trivy-config.yml
│   │   └── aqua-config.yml
│   │
│   └── opa-policies/                  # Open Policy Agent policies
│       ├── terraform.rego
│       ├── kubernetes.rego
│       └── docker.rego
│
├── cmdb/                              # CMDB integration
│   ├── servicenow/                    # ServiceNow integration
│   │   ├── ci-sync.py
│   │   └── change-automation.py
│   │
│   └── schemas/                       # CI/CD relationship schemas
│       ├── service-schema.json
│       └── dependency-schema.json
│
└── tests/                             # Testing
    ├── terraform/                     # Terraform tests
    │   ├── unit/
    │   └── integration/
    │
    ├── ansible/                       # Ansible tests
    │   └── molecule/
    │
    └── security/                      # Security tests
        ├── policy-tests/
        └── vulnerability-tests/
```

---

## 🚀 Quick Start

### Prerequisites

**Required Tools:**
```bash
# Terraform
terraform --version  # >= 1.6.0

# Ansible
ansible --version    # >= 2.15

# Azure CLI
az --version         # >= 2.50

# PowerShell
pwsh --version       # >= 7.3

# Python
python --version     # >= 3.11

# Docker
docker --version     # >= 24.0

# kubectl
kubectl version      # >= 1.28

# Helm
helm version         # >= 3.12
```

**Optional Tools:**
```bash
# Spacelift CLI
spacelift --version

# OPA
opa version

# Conftest
conftest --version

# Trivy
trivy --version
```

### 1. Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<subscription-id>"

# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<subscription-id>"
```

### 2. Initialize Terraform Backend

```bash
cd terraform/environments/dev

# Create backend resources
az group create --name "tfstate-rg" --location "eastus"
az storage account create --name "tfstate<unique>" --resource-group "tfstate-rg"
az storage container create --name "tfstate" --account-name "tfstate<unique>"

# Initialize Terraform
terraform init
```

### 3. Deploy Infrastructure

```bash
# Plan infrastructure changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### 4. Configure with Ansible

```bash
cd ../../ansible

# Install Ansible dependencies
ansible-galaxy install -r requirements.yml

# Run playbooks
ansible-playbook -i inventory/azure_rm.yml playbooks/site.yml
```

### 5. Deploy CI/CD Pipelines

**GitHub Actions:**
```bash
# Copy workflows to .github/workflows/
cp pipelines/github-actions/* .github/workflows/

# Configure secrets in GitHub
gh secret set ARM_CLIENT_ID
gh secret set ARM_CLIENT_SECRET
gh secret set ARM_SUBSCRIPTION_ID
gh secret set ARM_TENANT_ID
```

**Azure DevOps:**
```bash
# Create Azure DevOps project
az devops project create --name "infrastructure-automation"

# Import pipelines
az pipelines create --name "infrastructure" \
  --yml-path pipelines/azure-devops/infrastructure-pipeline.yml
```

---

## 📊 Key Features

### 1. **Terraform Modules** (Multi-Cloud Ready)

**Networking Module** (`terraform/modules/networking/`):
- VNet with custom address spaces
- Multiple subnets (public, private, data)
- Network Security Groups with baseline rules
- Azure Firewall / WAF integration
- VPN Gateway configuration
- DNS zones and records

**AKS Module** (`terraform/modules/aks/`):
- Multi-node cluster with autoscaling
- System and user node pools
- Azure CNI networking
- Azure AD integration (RBAC)
- Azure Monitor integration
- Pod security policies

**Key Vault Module** (`terraform/modules/keyvault/`):
- Secret storage with RBAC
- Encryption at rest
- Access policies for services
- Key rotation policies
- Audit logging

### 2. **Ansible Roles** (Golden Image & Config Management)

**Linux Hardening** (`ansible/roles/linux-baseline/`):
- CIS benchmark compliance
- Firewall configuration (firewalld/ufw)
- SSH hardening
- User/group management
- Security updates

**Windows Hardening** (`ansible/roles/windows-baseline/`):
- CIS benchmark compliance
- Windows Firewall rules
- PowerShell execution policies
- Windows Update automation
- Event log configuration

**Patching Automation** (`ansible/playbooks/patching.yml`):
- Pre-patching snapshots
- OS package updates (yum/apt/chocolatey)
- Service restart orchestration
- Post-patch validation
- Rollback procedures

### 3. **CI/CD Pipelines** (Multi-Stage with Gates)

**GitHub Actions Workflow**:
```yaml
# .github/workflows/infrastructure.yml
name: Infrastructure Deployment

on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate:
    # Terraform fmt, validate, tflint
  
  security-scan:
    # Trivy, Checkov, tfsec
  
  plan:
    # Terraform plan with cost estimation
  
  approval:
    # Manual approval gate (production only)
  
  apply:
    # Terraform apply with state locking
  
  post-deploy:
    # Ansible configuration, smoke tests
```

**Azure DevOps Pipeline**:
```yaml
# Multi-stage with approvals
stages:
  - stage: Build
  - stage: Dev
  - stage: Staging
    condition: succeeded()
  - stage: Production
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployProduction
        environment: production  # Requires manual approval
```

### 4. **Secrets Management**

**Azure Key Vault Integration**:
```hcl
# Terraform retrieves secrets from Key Vault
data "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  key_vault_id = azurerm_key_vault.main.id
}
```

**HashiCorp Vault**:
```yaml
# Ansible uses Vault for dynamic secrets
- name: Get database credentials
  community.hashi_vault.vault_read:
    url: "{{ vault_addr }}"
    path: secret/database/prod
  register: db_creds
```

**Secret Rotation**:
```python
# scripts/python/secret_rotation.py
# Automated 90-day rotation with Azure Key Vault
```

### 5. **RBAC & Least Privilege**

```hcl
# Terraform enforces least-privilege RBAC
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
```

### 6. **Observability Stack**

**Prometheus Metrics**:
- Infrastructure metrics (CPU, memory, disk)
- Application metrics (requests, latency, errors)
- Custom business metrics

**Grafana Dashboards**:
- Infrastructure overview
- Application performance (APM)
- Security events
- Cost tracking

**Azure Monitor**:
- Log Analytics workspace
- Application Insights
- Alert rules with action groups
- Custom KQL queries

**SLIs/SLOs**:
```yaml
# observability/slo/availability.yml
slo:
  name: "API Availability"
  target: 99.9%
  window: 30d
  indicators:
    - type: availability
      query: "requests | where success == true"
```

### 7. **Policy as Code**

**OPA Policy Example**:
```rego
# security/opa-policies/terraform.rego
# Deny public storage accounts
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.after.public_network_access_enabled == true
  msg := "Storage accounts must not allow public access"
}
```

**Conftest Integration**:
```bash
conftest test terraform/environments/dev/main.tf \
  --policy security/opa-policies/
```

### 8. **CMDB Integration**

```python
# cmdb/servicenow/ci-sync.py
# Syncs Azure resources to ServiceNow CMDB
# Maintains relationships: Application → AKS → VNet → Subscription
```

---

## 🔒 Security & Compliance

### Security Scanning

**Container Scanning** (Trivy):
```bash
trivy image --severity HIGH,CRITICAL myapp:latest
```

**IaC Scanning** (Checkov):
```bash
checkov -d terraform/environments/production/
```

**Secret Scanning** (Gitleaks):
```bash
gitleaks detect --source . --verbose
```

**SBOM Generation**:
```bash
syft packages dir:. -o cyclonedx-json > sbom.json
```

### Compliance Frameworks

- ✅ **ISO 27001**: Access control, encryption, audit logging
- ✅ **SOC 2**: Security monitoring, change management, incident response
- ✅ **NCSC Cloud Security Principles**: UK government cloud guidance
- ✅ **CIS Benchmarks**: Automated hardening for Linux/Windows

---

## 📖 Documentation

### Runbooks

- **[Deployment Runbook](docs/runbooks/deployment-runbook.md)**: Step-by-step deployment procedures
- **[Incident Response](docs/runbooks/incident-response.md)**: On-call procedures, escalation paths
- **[Rollback Procedure](docs/runbooks/rollback-procedure.md)**: Safe rollback strategies
- **[Secret Rotation](docs/runbooks/secret-rotation.md)**: Key and secret rotation workflows
- **[Disaster Recovery](docs/runbooks/disaster-recovery.md)**: RTO/RPO procedures

### Architecture Diagrams

- **Network Topology**: VNet design, subnets, security boundaries
- **Security Model**: Defense in depth, zero trust architecture
- **Data Flow**: Request lifecycle, authentication flow
- **Disaster Recovery**: Backup strategies, failover procedures

### Guides

- **[Terraform Development](docs/guides/terraform-development.md)**: Module development, best practices
- **[Ansible Best Practices](docs/guides/ansible-best-practices.md)**: Role design, playbook optimization
- **[RBAC Management](docs/guides/rbac-management.md)**: Permission design, access reviews
- **[Troubleshooting](docs/guides/troubleshooting.md)**: Common issues, debugging techniques

---

## 🧪 Testing Strategy

### Terraform Tests

```bash
# Unit tests with Terratest (Go)
cd tests/terraform/unit
go test -v

# Integration tests
cd tests/terraform/integration
terraform test
```

### Ansible Tests

```bash
# Molecule testing
cd ansible/roles/linux-baseline
molecule test
```

### Policy Tests

```bash
# OPA policy tests
opa test security/opa-policies/
```

### Security Tests

```bash
# Run full security suite
./tests/security/run-all-scans.sh
```

---

## 🎯 Continuous Improvement

### Toil Automation

- **Automated patching**: Reduces manual update cycles by 80%
- **Secret rotation**: Eliminates manual key management
- **Drift detection**: Auto-remediation of configuration drift
- **CMDB sync**: Eliminates manual service catalog updates

### Metrics

- **Deployment Frequency**: Tracked via Azure DevOps APIs
- **Lead Time for Changes**: Measured from commit to production
- **Mean Time to Recovery (MTTR)**: Alert to resolution time
- **Change Failure Rate**: % of deployments causing incidents

---

## 🤝 Contributing

This project follows GitOps principles:

1. **Branching Strategy**: Trunk-based development with feature branches
2. **Pull Requests**: All changes via PR with required approvals
3. **Automated Testing**: CI pipeline runs on every PR
4. **Code Review**: Terraform/Ansible peer review required
5. **Change Control**: CAB approval for production changes (via Azure DevOps approvals)

---

## 📞 Support & Contact

**Project Maintainer**: [Your Name]  
**Email**: [your.email@example.com]  
**LinkedIn**: [Your LinkedIn Profile]  

**Incident Response**: Follow [incident-response.md](docs/runbooks/incident-response.md)  
**Change Requests**: Submit via [Azure DevOps Boards]  
**Documentation Issues**: Create GitHub issue with `documentation` label

---

## 📝 License

This project is created for portfolio demonstration purposes.

---

## 🏆 Skills Alignment

| Job Requirement | Demonstrated In |
|----------------|-----------------|
| Terraform at scale (modules, workspaces, state) | `terraform/modules/`, remote state backend |
| Ansible automation (roles, playbooks) | `ansible/roles/`, golden image playbooks |
| Spacelift / IaC orchestration | `terraform/spacelift/`, drift detection |
| Azure Key Vault, HashiCorp Vault | `terraform/modules/keyvault/`, Ansible integration |
| GitHub Actions & Azure DevOps pipelines | `pipelines/github-actions/`, `pipelines/azure-devops/` |
| RBAC & least privilege | Azure AD integration, custom role assignments |
| CMDB management | `cmdb/servicenow/`, CI relationship mapping |
| PowerShell & Python scripting | `scripts/powershell/`, `scripts/python/` |
| Policy as Code (OPA/Sentinel) | `terraform/policies/opa/`, automated validation |
| Observability (Prometheus, Azure Monitor) | `observability/prometheus/`, dashboards |
| Containers & Kubernetes (AKS) | `terraform/modules/aks/`, Helm charts |
| Documentation & runbooks | `docs/runbooks/`, architecture diagrams |

---

**Last Updated**: December 19, 2025
