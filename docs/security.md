# YO Network Validator Security Guide

This guide covers essential security practices for running a YO Network validator safely and securely.

## 🔐 Key Security Principles

### 1. Validator Key Protection
Your validator private key is the most critical component. If compromised, an attacker can:
- Control your validator
- Participate in malicious consensus behavior
- Cause your validator to be slashed or removed

### 2. Network Security
Your validator communicates with the network and other validators. Secure this communication to prevent:
- Denial of Service (DoS) attacks
- Network reconnaissance
- Man-in-the-middle attacks

### 3. System Security
Keep your host system secure to protect all validator components from:
- Unauthorized access
- Malware and rootkits
- Privilege escalation attacks

## 🔑 Validator Key Security

### Key Generation Best Practices

**Use secure random generation:**
```bash
# Generate on air-gapped machine if possible
./scripts/generate-keys.sh

# Verify randomness source
cat /proc/sys/kernel/random/entropy_avail
# Should be > 1000
```

**Key file permissions:**
```bash
# Set restrictive permissions
chmod 600 validator/key
chmod 700 validator/

# Verify permissions
ls -la validator/
# Should show: -rw------- key
```

**Key storage options:**

1. **File-based (Default):**
   ```bash
   # Store in encrypted filesystem
   sudo cryptsetup luksFormat /dev/sdX
   sudo cryptsetup open /dev/sdX validator-keys
   sudo mkfs.ext4 /dev/mapper/validator-keys
   sudo mount /dev/mapper/validator-keys /path/to/keys
   ```

2. **Hardware Security Module (HSM):**
   ```bash
   # For enterprise setups
   # Configure HSM integration in docker-compose.yml
   ```

3. **Key derivation from mnemonic:**
   ```bash
   # For disaster recovery
   # Store mnemonic securely offline
   ```

### Key Backup Strategy

**Create encrypted backups:**
```bash
# Backup validator key
gpg --symmetric --cipher-algo AES256 validator/key
# Creates validator/key.gpg

# Store in multiple secure locations:
# 1. Encrypted USB drive (offline)
# 2. Secure cloud storage
# 3. Hardware wallet
# 4. Bank safe deposit box
```

**Test backup recovery:**
```bash
# Regularly test backup restoration
gpg --decrypt validator/key.gpg > /tmp/test-key
diff validator/key /tmp/test-key
rm /tmp/test-key
```

### Key Rotation

**Emergency key rotation:**
```bash
# If key compromise suspected:
# 1. Stop validator immediately
docker compose down

# 2. Generate new key
./scripts/generate-keys.sh

# 3. Update network registry (if applicable)
# 4. Restart with new key
docker compose up -d
```

## 🌐 Network Security

### Firewall Configuration

**Ubuntu/Debian (UFW):**
```bash
# Reset firewall
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH access (change port from 22)
sudo ufw allow from YOUR_IP to any port 2222

# Validator P2P
sudo ufw allow 30303/tcp comment "Besu P2P"

# RPC (localhost only - no external access)
sudo ufw deny 8545

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

**CentOS/RHEL (firewalld):**
```bash
# Start firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Create validator zone
sudo firewall-cmd --permanent --new-zone=validator
sudo firewall-cmd --permanent --zone=validator --add-port=30303/tcp
sudo firewall-cmd --permanent --zone=validator --add-port=2222/tcp

# Apply changes
sudo firewall-cmd --reload
```

### SSH Hardening

**Disable password authentication:**
```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Add/modify these lines:
Port 2222
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

**Use SSH keys only:**
```bash
# Generate SSH key pair (on your local machine)
ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/yo-validator

# Copy public key to validator
ssh-copy-id -i ~/.ssh/yo-validator.pub -p 2222 user@validator-ip

# Test connection
ssh -i ~/.ssh/yo-validator -p 2222 user@validator-ip
```

### VPN Access (Recommended)

**WireGuard setup:**
```bash
# Install WireGuard
sudo apt update
sudo apt install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Server config (/etc/wireguard/wg0.conf)
[Interface]
PrivateKey = <server-private-key>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32

# Start VPN
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

### DDoS Protection

**Rate limiting (iptables):**
```bash
# Limit new connections
sudo iptables -A INPUT -p tcp --dport 30303 -m state --state NEW -m recent --set
sudo iptables -A INPUT -p tcp --dport 30303 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j DROP

# SYN flood protection
sudo iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
sudo iptables -A INPUT -p tcp --syn -j DROP

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

**Fail2ban for SSH:**
```bash
# Install fail2ban
sudo apt install fail2ban

# Configure (/etc/fail2ban/jail.local)
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

sudo systemctl restart fail2ban
```

## 🖥️ System Security

### Operating System Hardening

**Keep system updated:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt autoremove

# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Disable unnecessary services:**
```bash
# Check running services
sudo systemctl list-units --type=service --state=running

# Disable unnecessary services
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable avahi-daemon.service

# Remove unnecessary packages
sudo apt autoremove --purge
```

**File integrity monitoring:**
```bash
# Install AIDE
sudo apt install aide

# Initialize database
sudo aideinit

# Check for changes
sudo aide --check
```

### User Account Security

**Create dedicated validator user:**
```bash
# Create non-privileged user
sudo useradd -m -s /bin/bash validator-user

# Add to docker group only
sudo usermod -aG docker validator-user

# Set up sudo access for specific commands only
sudo visudo
# Add: validator-user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart docker

# Switch to validator user
sudo su - validator-user
```

**Disable unused accounts:**
```bash
# List all users
cut -d: -f1 /etc/passwd

# Disable unused accounts
sudo usermod --expiredate 1 username
```

### Docker Security

**Docker daemon security:**
```bash
# Create docker daemon config
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "icc": false,
  "userns-remap": "default"
}
EOF

sudo systemctl restart docker
```

**Container security in docker-compose.yml:**
```yaml
services:
  besu-validator:
    # Run as non-root user
    user: "1000:1000"
    
    # Security options
    security_opt:
      - no-new-privileges:true
      - seccomp:unconfined
    
    # Read-only root filesystem
    read_only: true
    
    # Limited capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    
    # Resource limits
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: "2.0"
```

### Monitoring and Alerting

**System monitoring:**
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Set up log monitoring
sudo tail -f /var/log/syslog | grep -i error &
sudo tail -f /var/log/auth.log &
```

**Security monitoring script:**
```bash
#!/bin/bash
# Create: /usr/local/bin/security-check.sh

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    echo "WARNING: $FAILED_LOGINS failed login attempts detected"
fi

# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage at $DISK_USAGE%"
fi

# Check validator process
if ! docker compose ps | grep -q "Up"; then
    echo "CRITICAL: Validator container not running"
fi

# Run every 5 minutes
# Add to crontab: */5 * * * * /usr/local/bin/security-check.sh
```

## 🚨 Incident Response

### Security Incident Checklist

**Immediate Response:**
1. **Stop validator immediately:**
   ```bash
   docker compose down
   ```

2. **Isolate system:**
   ```bash
   # Disconnect from network
   sudo ip link set eth0 down
   
   # Or block all traffic
   sudo iptables -P INPUT DROP
   sudo iptables -P OUTPUT DROP
   ```

3. **Preserve evidence:**
   ```bash
   # Copy logs before they rotate
   sudo cp /var/log/syslog /tmp/incident-syslog
   sudo cp /var/log/auth.log /tmp/incident-auth
   docker compose logs > /tmp/incident-docker.log
   ```

**Investigation:**
1. **Check for unauthorized access:**
   ```bash
   # Recent logins
   last -n 20
   
   # Check sudo usage
   grep sudo /var/log/auth.log | tail -20
   
   # Check running processes
   ps aux
   
   # Check network connections
   netstat -tulpn
   ```

2. **File integrity check:**
   ```bash
   # Check if key files were modified
   ls -la validator/
   stat validator/key
   
   # Check system files
   sudo aide --check
   ```

**Recovery:**
1. **If key compromised:**
   - Generate new validator key
   - Update network registration
   - Report to network administrators

2. **If system compromised:**
   - Restore from clean backup
   - Re-harden system
   - Rotate all credentials

## 📋 Security Checklist

### Initial Setup
- [ ] Generated validator key securely
- [ ] Set restrictive file permissions (600 for key, 700 for directory)
- [ ] Created encrypted backup of validator key
- [ ] Configured firewall with minimal required ports
- [ ] Disabled password SSH authentication
- [ ] Changed default SSH port
- [ ] Created dedicated validator user account
- [ ] Hardened Docker daemon configuration
- [ ] Set up system monitoring

### Regular Maintenance
- [ ] Update system packages monthly
- [ ] Review firewall rules quarterly
- [ ] Test backup recovery procedure
- [ ] Check for security updates weekly
- [ ] Monitor system logs daily
- [ ] Verify validator key integrity
- [ ] Review user accounts and permissions
- [ ] Update Docker images

### Emergency Procedures
- [ ] Document incident response procedures
- [ ] Test isolation procedures
- [ ] Prepare clean system backup
- [ ] Establish communication channels
- [ ] Document key rotation process

## 🔗 Security Resources

### Tools
- **Lynis**: Security auditing tool
- **ClamAV**: Antivirus scanner
- **rkhunter**: Rootkit detector
- **OSSEC**: Host-based intrusion detection

### References
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [SSH Hardening Guide](https://stribika.github.io/2015/01/04/secure-secure-shell.html)

### Community
- YO Network Security Channel
- Validator Security Working Group
- Emergency Response Team: security@yo-network.org
