# Glowroot Central with ScyllaDB

High-performance monitoring setup using Glowroot Central with ScyllaDB as the backend database, optimized for high-throughput server environments.

## Overview

This configuration provides:
- **ScyllaDB**: High-performance NoSQL database (Cassandra-compatible)
- **Glowroot Central**: Application performance monitoring collector
- **Optimized Settings**: Tuned for high-throughput production environments
- **Docker Compose**: Easy deployment and management

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Java Apps    │───▶│ Glowroot Central │───▶│    ScyllaDB     │
│  (with agents)  │    │   (Collector)    │    │   (Storage)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │    Web UI        │
                       │  (Port 4000)     │
                       └──────────────────┘
```

## Quick Start

### Prerequisites

- Docker and Docker Compose
- At least 16GB RAM available for containers
- 100GB+ disk space for data storage

### 1. Create Data Directories

```bash
sudo mkdir -p /opt/data/{scylladb/{data,commitlog,hints,view_hints,logs},glowroot}
sudo chown -R $(id -u):$(id -g) /opt/data/
```

### 2. Start Services

```bash
# Start ScyllaDB first
docker-compose up -d scylladb

# Wait for ScyllaDB to be ready (check logs)
docker-compose logs -f scylladb

# Start Glowroot Central
docker-compose up -d glowroot-central
```

### 3. Access Web UI

- **Glowroot UI**: http://localhost:4000
- **ScyllaDB Monitoring**: http://localhost:9180/metrics (Prometheus metrics)

## Configuration Details

### ScyllaDB Configuration

**Resource Allocation:**
- **CPU**: 14 cores (`--smp=14`)
- **Memory**: 96GB total, 4GB reserved (`--memory=96G --reserve-memory=4G`)
- **Network**: Host networking for optimal performance

**Key Features:**
- Single-node setup with `SimpleStrategy` replication
- Optimized for high-throughput workloads
- Prometheus metrics enabled on port 9180
- Health checks with automatic retry logic

### Glowroot Central Configuration

**Performance Tuning:**
- **JVM Heap**: 24GB max, 16GB initial (`-Xmx24g -Xms16g`)
- **GC**: G1 garbage collector with 200ms pause target
- **Connection Pool**: 16-64 connections per host
- **Request Throttling**: 50,000 requests/second capacity

**Data Retention:**
- **Traces**: 14 days
- **Aggregates**: 90 days  
- **Gauges**: 90 days
- **Incidents**: 1 year

**Ports:**
- **Web UI**: 4000
- **gRPC (agents)**: 8181

### DataStax Driver Configuration

**Connection Settings:**
- **Protocol**: CQL v4
- **Consistency**: ONE (optimized for single node)
- **Pool Size**: 16 connections per host
- **Request Throttling**: 100,000 requests/second

**Request Profiles:**
- **slow**: 300 second timeout
- **collector**: 30 second timeout  
- **rollup**: 20 second timeout
- **web**: 20 second timeout

## Agent Configuration

To connect Java applications to this Glowroot Central instance:

### 1. Download Glowroot Agent

```bash
wget https://github.com/glowroot/glowroot/releases/download/v0.14.0/glowroot-agent-0.14.0.zip
unzip glowroot-agent-0.14.0.zip
```

### 2. Configure Agent

Create `glowroot/glowroot.properties`:

```properties
agent.id=my-application
collector.address=http://localhost:8181
```

### 3. Start Application with Agent

```bash
java -javaagent:glowroot/glowroot.jar -jar your-application.jar
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check ScyllaDB status
docker-compose exec scylladb nodetool status

# Check Glowroot Central health
curl http://localhost:4000/backend/config/health

# View container logs
docker-compose logs -f scylladb
docker-compose logs -f glowroot-central
```

### ScyllaDB Operations

```bash
# Connect to CQL shell
docker-compose exec scylladb cqlsh

# Check keyspaces
docker-compose exec scylladb cqlsh -e "DESCRIBE KEYSPACES;"

# Monitor performance
docker-compose exec scylladb nodetool cfstats glowroot
```

### Backup and Recovery

```bash
# Create ScyllaDB snapshot
docker-compose exec scylladb nodetool snapshot glowroot

# Backup Glowroot configuration
tar -czf glowroot-backup.tar.gz /opt/data/glowroot/
```

## Performance Tuning

### System Requirements

**Minimum Production Setup:**
- **CPU**: 16+ cores
- **RAM**: 128GB+ total system memory
- **Storage**: NVMe SSD with 10,000+ IOPS
- **Network**: 10Gbps+ for high-throughput environments

### OS Tuning

```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Disable swap for better performance
swapoff -a

# Tune kernel parameters
echo 'vm.max_map_count = 1048575' >> /etc/sysctl.conf
sysctl -p
```

### Scaling Considerations

**Single Node Limits:**
- ~50,000 requests/second
- ~1TB of monitoring data
- ~100 connected applications

**Multi-Node Scaling:**
- Update `cassandra.keyspaceReplication` to use `NetworkTopologyStrategy`
- Add additional ScyllaDB nodes to the cluster
- Increase connection pool sizes proportionally

## Troubleshooting

### Common Issues

**ScyllaDB Won't Start:**
```bash
# Check system resources
free -h
df -h /opt/data/scylladb/

# Review ScyllaDB logs
docker-compose logs scylladb
```

**Glowroot Central Connection Issues:**
```bash
# Verify ScyllaDB is accessible
docker-compose exec glowroot-central cqlsh scylladb -e "DESCRIBE KEYSPACES;"

# Check Glowroot logs
docker-compose logs glowroot-central
```

**High Memory Usage:**
- Reduce JVM heap size in docker-compose.yml
- Adjust ScyllaDB memory allocation
- Monitor with `docker stats`

### Performance Issues

**Slow Query Performance:**
- Check ScyllaDB metrics: http://localhost:9180/metrics
- Review connection pool utilization in Glowroot UI
- Consider increasing `maxRequestsPerSecond` limits

**Agent Connection Problems:**
- Verify gRPC port 8181 is accessible
- Check agent configuration and network connectivity
- Review agent logs for connection errors

## Security Considerations

### Production Deployment

**Network Security:**
- Use firewall rules to restrict access to ports 4000, 8181, 9042
- Consider TLS/SSL termination with reverse proxy
- Implement authentication for Glowroot UI

**Data Security:**
- Enable ScyllaDB authentication and authorization
- Use encrypted storage volumes
- Regular security updates for container images

### LDAP Integration

Uncomment and configure LDAP settings in `glowroot-central.properties`:

```properties
ldap.url=ldap://your-ldap-server:389
ldap.username=bind-user
ldap.password=bind-password
ldap.userSearchBase=ou=users,dc=company,dc=com
ldap.userSearchFilter=(uid={0})
```

## Support and Resources

- **Glowroot Documentation**: https://glowroot.org/
- **ScyllaDB Documentation**: https://docs.scylladb.com/
- **Docker Compose Reference**: https://docs.docker.com/compose/

For issues specific to this configuration, check the container logs and system resources first.
