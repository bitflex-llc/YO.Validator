# YO Network Validator Troubleshooting Guide

This guide covers common issues and solutions when running a YO Network validator.

## 🔍 Diagnostic Commands

### Check Container Status
```bash
# See all containers
docker compose ps

# Check if validator is running
docker compose ps | grep yo-validator

# View resource usage
docker stats yo-validator
```

### Check Logs
```bash
# View recent logs
docker compose logs besu-validator

# Follow logs in real-time
docker compose logs -f besu-validator

# View last 100 lines
docker compose logs --tail=100 besu-validator

# Search for errors
docker compose logs besu-validator | grep -i error
```

### Check Network Connectivity
```bash
# Test RPC endpoint
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545

# Check peer connections
curl -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545

# Test P2P connectivity
telnet yo-rpc.bcflex.com 30303
```

## 🚨 Common Issues and Solutions

### 1. Container Won't Start

#### Symptoms
- `docker compose up -d` fails
- Container exits immediately
- "Cannot start service" errors

#### Solutions

**Check Docker is running:**
```bash
sudo systemctl status docker
sudo systemctl start docker
```

**Check file permissions:**
```bash
chmod 600 validator/key
chmod 700 validator/
```

**Check port conflicts:**
```bash
# See what's using port 30303
sudo netstat -tulpn | grep 30303
sudo lsof -i :30303

# Kill conflicting processes if needed
sudo kill -9 <PID>
```

**Check disk space:**
```bash
df -h
docker system prune -f  # Clean up unused Docker data
```

### 2. Node Not Connecting to Peers

#### Symptoms
- Peer count is 0
- "Failed to connect to peer" in logs
- Node appears isolated

#### Solutions

**Check static-nodes.json:**
```bash
cat config/static-nodes.json
# Ensure it contains valid enode URLs
```

**Verify firewall settings:**
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 30303/tcp

# CentOS/RHEL
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=30303/tcp --permanent
sudo firewall-cmd --reload
```

**Test network connectivity:**
```bash
# Test each peer from static-nodes.json
telnet <peer-ip> <peer-port>

# Example:
telnet 172.19.0.6 30303
```

**Restart with fresh network state:**
```bash
docker compose down
docker compose up -d
```

### 3. Sync Issues

#### Symptoms
- Block number not increasing
- "Sync status: syncing" for extended periods
- Network appears stalled

#### Solutions

**Check if network is producing blocks:**
```bash
# Check network explorer
curl https://yo-bs.bcflex.com/api/v1/stats

# Check if other nodes are ahead
./scripts/check-sync.sh
```

**Reset blockchain data:**
```bash
docker compose down
docker volume rm yo-validator_validator-data
docker compose up -d
```

**Check genesis configuration:**
```bash
# Ensure genesis.json is correct
cat config/genesis.json
# Compare with network genesis
```

### 4. High Resource Usage

#### Symptoms
- High CPU usage
- Excessive memory consumption
- System becomes unresponsive

#### Solutions

**Optimize JVM settings:**
```bash
# For 4GB RAM system
export BESU_OPTS="-Xmx2g -Xms2g"

# For 8GB RAM system
export BESU_OPTS="-Xmx4g -Xms4g"

# Restart container
docker compose restart besu-validator
```

**Enable garbage collection logging:**
```bash
export BESU_OPTS="-Xmx2g -Xms2g -XX:+UseG1GC -XX:+PrintGC"
docker compose restart besu-validator
```

**Monitor resource usage:**
```bash
# Real-time monitoring
docker stats yo-validator

# System resources
htop
free -h
df -h
```

### 5. RPC Connection Issues

#### Symptoms
- "Connection refused" when calling RPC
- Curl commands timeout
- Web3 applications can't connect

#### Solutions

**Check RPC is enabled:**
```bash
# Verify RPC settings in logs
docker compose logs besu-validator | grep -i rpc

# Test local connection
curl http://localhost:8545
```

**Check port binding:**
```bash
# See what's listening on RPC port
sudo netstat -tulpn | grep 8545

# Verify Docker port mapping
docker compose ps
```

**Update RPC configuration:**
```yaml
# In docker-compose.yml, ensure:
ports:
  - "127.0.0.1:8545:8545"  # Localhost only
  # OR
  - "8545:8545"  # All interfaces (less secure)
```

### 6. Transaction Issues

#### Symptoms
- Transactions pending forever
- "Insufficient gas" errors
- Nonce errors

#### Solutions

**Check gas settings:**
```bash
# Get current gas price
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545
```

**Check account balance:**
```bash
# Replace with your address
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xYourAddress","latest"],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545
```

**Reset transaction pool:**
```bash
docker compose restart besu-validator
```

### 7. Permission Errors

#### Symptoms
- "Permission denied" errors
- Files cannot be read/written
- Container fails with permission errors

#### Solutions

**Fix file ownership:**
```bash
# Change ownership to current user
sudo chown -R $USER:$USER .

# Set proper permissions
chmod 600 validator/key
chmod 700 validator/
chmod 644 config/*.json
```

**Check Docker user settings:**
```yaml
# In docker-compose.yml
services:
  besu-validator:
    user: "1000:1000"  # Adjust to your user ID
```

**Get your user ID:**
```bash
id -u  # User ID
id -g  # Group ID
```

## 🔧 Advanced Debugging

### Enable Debug Logging
```bash
# Update LOG_LEVEL in .env
LOG_LEVEL=DEBUG

# Restart container
docker compose restart besu-validator
```

### Access Container Shell
```bash
# Get shell access to running container
docker exec -it yo-validator /bin/bash

# Check internal network connectivity
docker exec yo-validator ping besu-node1

# Check file permissions inside container
docker exec yo-validator ls -la /opt/besu/
```

### Network Analysis
```bash
# Check Docker network
docker network ls
docker network inspect yo-validator_yo-network

# Monitor network traffic
sudo tcpdump -i any port 30303

# Check routing
docker exec yo-validator route -n
```

### Database Issues
```bash
# Check blockchain database
docker exec yo-validator ls -la /opt/besu/data/

# Database corruption recovery
docker compose down
docker volume rm yo-validator_validator-data
docker compose up -d
```

## 📞 Getting Help

When seeking help, please provide:

1. **System Information:**
   ```bash
   uname -a
   docker --version
   docker compose version
   ```

2. **Container Status:**
   ```bash
   docker compose ps
   docker compose logs --tail=50 besu-validator
   ```

3. **Network Status:**
   ```bash
   ./scripts/check-sync.sh
   ```

4. **Configuration:**
   ```bash
   cat .env
   cat config/genesis.json
   ```

### Support Channels
- **GitHub Issues**: Technical problems and bugs
- **Discord**: Real-time community support  
- **Email**: validator-support@yo-network.org

## 📋 Maintenance Checklist

### Daily
- [ ] Check validator is running: `docker compose ps`
- [ ] Verify sync status: `./scripts/check-sync.sh`
- [ ] Monitor system resources: `docker stats yo-validator`

### Weekly
- [ ] Check for updates: `docker compose pull`
- [ ] Review logs for errors: `docker compose logs besu-validator | grep -i error`
- [ ] Verify peer connections
- [ ] Check disk space usage

### Monthly
- [ ] Backup validator keys
- [ ] Update system packages
- [ ] Review security settings
- [ ] Clean up Docker resources: `docker system prune`
