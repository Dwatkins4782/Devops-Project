# ELK Stack Implementation

This directory contains a complete ELK (Elasticsearch, Logstash, Kibana) Stack implementation for centralized logging and monitoring.

## 📁 Project Structure

```
.
├── helm/elk/                           # Kubernetes Helm chart for ELK Stack
│   ├── Chart.yaml                      # Helm chart metadata
│   ├── values.yaml                     # Configuration values
│   └── templates/                      # Kubernetes manifests
│       ├── elasticsearch-*.yaml        # Elasticsearch resources
│       ├── logstash-*.yaml            # Logstash resources
│       └── kibana-*.yaml              # Kibana resources
├── elk-config/                         # Local development configs
│   ├── logstash.yml                   # Logstash settings
│   ├── logstash.conf                  # Pipeline configuration
│   └── README.md                      # Local setup guide
├── docker-compose.elk.yml             # Docker Compose for local testing
├── scripts/
│   ├── deploy-elk.sh                  # Deployment script (Linux/Mac)
│   └── deploy-elk.ps1                 # Deployment script (Windows)
└── app/
    ├── app.py                         # Updated with Logstash logging
    └── requirements.txt               # Includes python-logstash-async
```

## 🚀 Quick Start

### Option 1: Local Development (Docker Compose)

Perfect for testing and development:

```bash
# Start ELK Stack + Application
docker-compose -f docker-compose.elk.yml up -d

# Wait for services (2-3 minutes)
docker-compose -f docker-compose.elk.yml logs -f

# Access Kibana
# Open: http://localhost:5601
```

See [elk-config/README.md](elk-config/README.md) for detailed local setup instructions.

### Option 2: Kubernetes Deployment (Production)

For production environments:

```bash
# Linux/Mac
./scripts/deploy-elk.sh

# Windows PowerShell
.\scripts\deploy-elk.ps1

# Or manually with Helm
helm install elk-stack ./helm/elk --namespace monitoring --create-namespace
```

## 📊 Components

### 1. Elasticsearch
- **Purpose**: Search and analytics engine, stores indexed logs
- **Port**: 9200 (HTTP API)
- **Configuration**: Single-node for dev, clustered for production
- **Storage**: 10GB persistent volume (configurable)

### 2. Logstash
- **Purpose**: Log processing pipeline (collect, parse, transform)
- **Ports**: 
  - 5000: TCP input (for application logs)
  - 5044: Beats input
  - 9600: Monitoring API
- **Pipeline**: Defined in `logstash.conf`

### 3. Kibana
- **Purpose**: Visualization and UI for Elasticsearch data
- **Port**: 5601
- **Features**: Log search, dashboards, visualizations

## 🔧 Configuration

### Application Integration

Your Python application ([app/app.py](app/app.py)) is already configured:

```python
# Sends structured logs to Logstash
logger.info("Request received", extra={
    'endpoint': '/api/hello',
    'method': 'GET',
    'status': 200
})
```

**Environment Variables:**
- `LOGSTASH_HOST`: Logstash hostname (default: `logstash`)
- `LOGSTASH_PORT`: Logstash port (default: `5000`)

### Helm Values Customization

Edit [helm/elk/values.yaml](helm/elk/values.yaml):

```yaml
elasticsearch:
  replicas: 3                    # Scale Elasticsearch
  resources:
    requests:
      memory: "4Gi"               # Increase memory
  persistence:
    size: 50Gi                    # Increase storage

kibana:
  service:
    type: LoadBalancer            # Expose externally
```

### Logstash Pipeline

Edit pipeline in [elk-config/logstash.conf](elk-config/logstash.conf):

```ruby
filter {
  # Add custom filters
  if [log_level] == "ERROR" {
    mutate {
      add_tag => ["error"]
    }
  }
}
```

## 📖 Usage

### 1. Initial Setup (First Time)

After deployment, configure Kibana:

1. Open Kibana at `http://<kibana-url>:5601`
2. Navigate to: **Management** → **Stack Management** → **Index Patterns**
3. Click **Create index pattern**
4. Enter: `logs-*`
5. Select time field: `@timestamp`
6. Click **Create**

### 2. View Logs

1. Go to **Analytics** → **Discover**
2. Select `logs-*` index pattern
3. Use search/filter to find logs

### 3. Create Dashboards

1. Go to **Analytics** → **Dashboard**
2. Click **Create dashboard**
3. Add visualizations (bar charts, line graphs, pie charts)

### 4. Common Searches

In Kibana Discover:

```
# Find errors
log_level: "ERROR"

# Specific endpoint
endpoint: "/api/hello"

# Time range + status
@timestamp: [now-1h TO now] AND status: 500

# Application-specific
app_name: "devops-app" AND environment: "production"
```

## 🔍 Monitoring

### Check ELK Health

```bash
# Elasticsearch cluster health
curl http://elasticsearch:9200/_cluster/health

# List indices
curl http://elasticsearch:9200/_cat/indices

# Logstash stats
curl http://logstash:9600/_node/stats

# Kubernetes pods
kubectl get pods -n monitoring
kubectl logs -f <pod-name> -n monitoring
```

### Application Logs

```bash
# Docker Compose
docker-compose -f docker-compose.elk.yml logs app

# Kubernetes
kubectl logs -f deployment/devops-app
```

## 🛠️ Troubleshooting

### No Logs in Kibana

1. **Check application connection:**
   ```bash
   kubectl logs -f deployment/devops-app | grep -i logstash
   ```

2. **Verify Logstash is receiving data:**
   ```bash
   kubectl logs -f deployment/elk-stack-logstash
   ```

3. **Check Elasticsearch indices:**
   ```bash
   curl http://elasticsearch:9200/_cat/indices?v
   ```

### Elasticsearch Memory Issues

Increase memory in Docker Desktop settings (4GB minimum) or Kubernetes resources:

```yaml
elasticsearch:
  resources:
    requests:
      memory: "4Gi"
```

### Kibana Not Accessible

```bash
# Port forward (temporary access)
kubectl port-forward svc/kibana 5601:5601 -n monitoring

# Access at http://localhost:5601
```

## 📈 Performance Tuning

### Elasticsearch

```yaml
# values.yaml
elasticsearch:
  replicas: 3                     # High availability
  env:
    - name: ES_JAVA_OPTS
      value: "-Xms4g -Xmx4g"     # Heap size (50% of RAM)
  persistence:
    size: 100Gi                   # Adequate storage
```

### Logstash

```yaml
logstash:
  replicas: 2                     # Load balancing
  resources:
    requests:
      cpu: "1000m"
      memory: "2Gi"
```

## 🔒 Security (Production)

### Enable X-Pack Security

```yaml
elasticsearch:
  env:
    - name: xpack.security.enabled
      value: "true"
```

### Create Users

```bash
# Set passwords
kubectl exec -it elk-stack-elasticsearch-0 -- \
  /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
```

### Use TLS

Configure certificates for Elasticsearch, Logstash, and Kibana communication.

## 🗑️ Cleanup

### Remove from Kubernetes

```bash
helm uninstall elk-stack -n monitoring
kubectl delete namespace monitoring
```

### Stop Docker Compose

```bash
docker-compose -f docker-compose.elk.yml down -v
```

## 📚 Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [ELK Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-best-practices.html)

## 🎯 Next Steps

1. **Deploy to Kubernetes**: Run `./scripts/deploy-elk.sh`
2. **Configure Index Patterns**: Set up `logs-*` in Kibana
3. **Deploy Application**: Ensure app sends logs to Logstash
4. **Create Dashboards**: Build visualizations for your logs
5. **Set Up Alerts**: Configure Kibana alerting rules
6. **Enable Security**: Add authentication for production
