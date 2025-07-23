# YO Network Validator Setup

This repository contains everything needed to set up and run a YO Network validator node.

## Prerequisites

- Docker and Docker Compose
- Linux server with at least 4GB RAM
- Open ports: 30303, 8545, 8546
- Stable internet connection

## Quick Setup

1. Clone this repository
2. Run the setup script: `./setup-validator.sh`
3. Your validator will start automatically

## Network Information

- **Chain ID**: 2025
- **Network Name**: YO Network
- **Consensus**: IBFT 2.0
- **Block Time**: 2 seconds
- **Static Node**: 194.164.150.169:30303

## Manual Setup

### 1. Generate Validator Keys

```bash
# Generate new validator private key and address
./scripts/generate-keys.sh
```

### 2. Configure Environment

Copy the generated validator address to your `.env` file as MINER_COINBASE.

### 3. Start Validator

```bash
docker compose up -d
```

## Monitoring

Check validator status:
```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -H "Content-Type: application/json" http://localhost:8545
```

## Support

For issues and questions, please open an issue in this repository.
```

### 4. Verify Installation
```bash
# Check if your node is running
docker compose logs besu-validator

# Check peer connections
curl -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545
```

## 📖 Detailed Setup Instructions

### Step 1: Prepare Your Server

#### Install Docker
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install -y docker docker-compose
sudo systemctl enable docker
sudo systemctl start docker
```

#### Configure Firewall
```bash
# Allow required ports
sudo ufw allow 30303/tcp  # P2P communication
sudo ufw allow 8545/tcp   # RPC (optional, for monitoring)
sudo ufw enable
```

### Step 2: Generate Validator Keys

```bash
# Run the key generation script
./scripts/generate-keys.sh

# This will create:
# - Private key for your validator
# - Public key and address
# - Node configuration files
```

### Step 3: Configure Your Node

1. **Update Environment Variables**
   ```bash
   cp config/.env.example .env
   nano .env
   ```

2. **Set Your Validator Address**
   ```bash
   # Add your generated validator address
   VALIDATOR_ADDRESS=0xYourValidatorAddressHere
   ```

3. **Configure Network Settings**
   ```bash
   # Customize if needed
   P2P_PORT=30303
   RPC_PORT=8545
   NETWORK_ID=2025
   ```

### Step 4: Join the Network

1. **Get Network Configuration**
   ```bash
   # Download genesis and static nodes
   ./scripts/download-network-config.sh
   ```

2. **Start Your Validator**
   ```bash
   docker compose up -d
   ```

3. **Monitor Startup**
   ```bash
   # Watch logs
   docker compose logs -f besu-validator
   
   # Check sync status
   ./scripts/check-sync.sh
   ```

## 🔧 Configuration Files

### Docker Compose Structure
```yaml
services:
  besu-validator:
    image: hyperledger/besu:24.6.0
    container_name: yo-validator
    # ... configuration
```

### Key Files
- `docker-compose.yml` - Main container configuration
- `config/genesis.json` - Network genesis configuration
- `config/static-nodes.json` - Known peer nodes
- `validator/key` - Your private validator key
- `.env` - Environment variables

## 📊 Monitoring Your Validator

### Health Checks
```bash
# Check if your node is healthy
curl http://localhost:8545/health

# Get latest block number
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545

# Check peer count
curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  -H "Content-Type: application/json" http://localhost:8545
```

### Useful Commands
```bash
# View logs
docker compose logs besu-validator

# Restart validator
docker compose restart besu-validator

# Update to latest version
docker compose pull && docker compose up -d

# Check disk usage
du -sh data/
```

## 🛠️ Troubleshooting

### Common Issues

#### Node Not Connecting to Peers
```bash
# Check static-nodes.json is correct
cat config/static-nodes.json

# Verify firewall settings
sudo ufw status

# Check network connectivity
telnet yo-rpc.bcflex.com 30303
```

#### Sync Issues
```bash
# Reset blockchain data (will re-sync)
docker compose down
docker volume rm yo-validator_validator-data
docker compose up -d
```

#### Performance Issues
```bash
# Check system resources
docker stats yo-validator

# Optimize JVM settings
export BESU_OPTS="-Xmx4g -Xms4g"
docker compose up -d
```

### Getting Help

1. **Check Logs**: Always start with `docker compose logs`
2. **Network Status**: Visit [https://yo-bs.bcflex.com](https://yo-bs.bcflex.com)
3. **Community**: Join our Discord/Telegram for support
4. **Issues**: Report bugs on GitHub Issues

## 🔒 Security Best Practices

### Key Management
- **Never share your private key**
- Store keys securely with proper file permissions
- Regular backups of validator keys
- Use hardware security modules for production

### Network Security
- Run validators behind firewalls
- Use VPN for remote access
- Regular security updates
- Monitor for unusual activity

### Operational Security
```bash
# Set proper file permissions
chmod 600 validator/key
chmod 700 validator/

# Regular updates
docker compose pull
sudo apt update && sudo apt upgrade

# Monitor logs for anomalies
grep -i error logs/besu.log
```

## 📈 Validator Economics

### Requirements
- Minimum stake: TBD
- Hardware requirements: 4GB RAM, 100GB SSD
- Network uptime: 99%+ recommended

### Rewards
- Block rewards for successful validation
- Transaction fees from processed blocks
- Network participation incentives

## 🤝 Contributing

We welcome contributions to improve the validator setup process:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Development Setup
```bash
# Clone for development
git clone https://github.com/your-username/YO.Validator.git
cd YO.Validator

# Install development tools
npm install -g @commitlint/cli
pre-commit install
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Useful Links

- **Explorer**: [https://yo-bs.bcflex.com](https://yo-bs.bcflex.com)
- **RPC Endpoint**: [https://yo-rpc.bcflex.com](https://yo-rpc.bcflex.com)
- **Documentation**: [docs/](docs/)
- **Support**: Create an issue on GitHub

## 📞 Support

- **GitHub Issues**: Technical problems and bugs
- **Discord**: Real-time community support
- **Email**: validator-support@yo-network.org

---

**Happy Validating! 🎉**

*Built with ❤️ for the YO Network community*
