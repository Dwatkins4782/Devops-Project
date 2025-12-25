# ELK Stack Local Development Guide

This directory contains configuration files for running the ELK Stack locally using Docker Compose.

## Quick Start

### 1. Start ELK Stack

```bash
# Start all services
docker-compose -f docker-compose.elk.yml up -d

# View logs
docker-compose -f docker-compose.elk.yml logs -f
```

### 2. Wait for Services to Start

It may take 2-3 minutes for all services to be fully ready.

```bash
# Check service health
docker-compose -f docker-compose.elk.yml ps

# Wait for Elasticsearch to be ready
curl http://localhost:9200/_cluster/health

# Wait for Kibana to be ready
curl http://localhost:5601/api/status
```

### 3. Access Services

- **Kibana UI**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200
- **Application**: http://localhost:8080

### 4. Configure Kibana

1. Open Kibana at http://localhost:5601
2. Go to **Management** → **Stack Management** → **Index Patterns**
3. Click **Create index pattern**
4. Enter `logs-*` as the index pattern
5. Select `@timestamp` as the time field
6. Click **Create index pattern**

### 5. View Logs

1. Go to **Analytics** → **Discover** in Kibana
2. Select the `logs-*` index pattern
3. You should see logs from your application

### 6. Generate Some Logs

```bash
# Make some requests to generate logs
curl http://localhost:8080/
curl http://localhost:8080/api/hello?name=DevOps
curl http://localhost:8080/health
```

## Configuration Files

- `docker-compose.elk.yml` - Docker Compose configuration
- `elk-config/logstash.yml` - Logstash service configuration
- `elk-config/logstash.conf` - Logstash pipeline configuration

## Customization

### Change Elasticsearch Memory

Edit `docker-compose.elk.yml`:

```yaml
elasticsearch:
  environment:
    - "ES_JAVA_OPTS=-Xms2g -Xmx2g"  # Change from 1g to 2g
```

### Add Custom Logstash Filters

Edit `elk-config/logstash.conf` and add your filters in the `filter` block.

### Change Ports

Edit the ports section in `docker-compose.elk.yml`:

```yaml
kibana:
  ports:
    - "5602:5601"  # Change host port to 5602
```

## Troubleshooting

### Elasticsearch won't start (memory issues)

Increase Docker memory limit to at least 4GB:
- Docker Desktop → Settings → Resources → Memory → 4GB+

### No logs appearing in Kibana

1. Check if Logstash is receiving logs:
   ```bash
   docker-compose -f docker-compose.elk.yml logs logstash
   ```

2. Check if application is connected:
   ```bash
   docker-compose -f docker-compose.elk.yml logs app
   ```

3. Verify Elasticsearch has indices:
   ```bash
   curl http://localhost:9200/_cat/indices
   ```

### Reset Everything

```bash
# Stop and remove all containers, networks, and volumes
docker-compose -f docker-compose.elk.yml down -v

# Start fresh
docker-compose -f docker-compose.elk.yml up -d
```

## Production Considerations

For production deployment:

1. **Enable Security**: Set `xpack.security.enabled=true` and configure authentication
2. **Use Persistent Volumes**: Configure proper volume mounts for data persistence
3. **Resource Limits**: Set appropriate CPU and memory limits
4. **High Availability**: Deploy multiple Elasticsearch nodes
5. **Monitoring**: Enable X-Pack monitoring or use Metricbeat
6. **Backup**: Configure snapshot repositories for backups

## Stop Services

```bash
# Stop all services
docker-compose -f docker-compose.elk.yml down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose -f docker-compose.elk.yml down -v
```
