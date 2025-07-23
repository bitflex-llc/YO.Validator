#!/bin/bash

# YO Network Validator Setup Script
# This script automates the setup process for running a YO Network validator

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BESU_VERSION="24.6.0"
NETWORK_ID="2025"
CHAIN_ID="2025"

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check available disk space (minimum 10GB)
    available_space=$(df . | awk 'NR==2 {print $4}')
    required_space=10485760  # 10GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        print_warning "Available disk space is less than 10GB. Consider freeing up space."
    fi
    
    # Check available RAM (minimum 4GB)
    total_ram=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_ram -lt 4000 ]]; then
        print_warning "Available RAM is less than 4GB. Performance may be affected."
    fi
    
    print_success "System requirements check completed"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p validator
    mkdir -p data
    mkdir -p logs
    mkdir -p config
    
    print_success "Directories created"
}

# Generate validator keys
generate_keys() {
    print_status "Generating validator keys..."
    
    if [[ -f "validator/key" ]]; then
        print_warning "Validator key already exists. Skipping key generation."
        return
    fi
    
    # Generate a random private key
    private_key=$(openssl rand -hex 32)
    echo "0x${private_key}" > validator/key
    chmod 600 validator/key
    
    print_success "Validator keys generated"
    print_warning "IMPORTANT: Backup your validator key in a secure location!"
    echo "Private key saved to: validator/key"
}

# Download network configuration
download_network_config() {
    print_status "Downloading network configuration..."
    
    # Create genesis.json
    cat > config/genesis.json << 'EOF'
{
  "config" : {
    "chainId" : 2025,
    "berlinBlock" : 0,
    "londonBlock" : 0,
    "ibft2" : {
      "blockperiodseconds" : 2,
      "epochlength" : 30000,
      "requesttimeoutseconds" : 10
    }
  },
  "nonce" : "0x0",
  "timestamp" : "0x58ee40ba",
  "gasLimit" : "0x1fffffffffffff",
  "difficulty" : "0x1",
  "mixHash" : "0x63746963616c2d6279706173732d686561646572",
  "coinbase" : "0x0000000000000000000000000000000000000000",
  "alloc" : {
    "0x33D8dD5A4F871b8f78aBD7C5d82289bC026890C0" : {
      "balance" : "1000000000000000000000000000000"
    }
  },
  "extraData" : "0xf869a00000000000000000000000000000000000000000000000000000000000000000f83f944d59ac9fcf2048b558da1f91c2325d2c3957051a948922bccafed2fcf6775cfeebee309392230a616a9437188f19f6bd38543575487a7f3d510a4737e265808400000000c0"
}
EOF

    # Create static-nodes.json (will be populated by network admin)
    cat > config/static-nodes.json << 'EOF'
[
  "enode://c1f740958e39b1a880712f979ab144fa1f98fe3f96eebf86fd2d530b5f5d1a232a3aec3b13b93aa4fb4236418f9a523ee7156cb60eb847aec60edc5075508932@172.19.0.6:30303",
  "enode://4f6d4135e0e749473afeedc22b4ceabff1f9e1b072c250297f195eef10fc0e74df01a1abd376dffcf56c023fff8aad560abeb95724cbc128b5a72621735fce70@172.19.0.4:30304",
  "enode://fbf5f5567a67c0c33696c24d698cdbd89160af125e3c2a7866abca1980f5ca0fdc7c9dd3df5d8f05f99cf0a3b96927d6279aa953c4258173341f66cdcb384eb9@172.19.0.2:30305"
]
EOF
    
    print_success "Network configuration downloaded"
}

# Create environment file
create_env_file() {
    print_status "Creating environment configuration..."
    
    if [[ -f ".env" ]]; then
        print_warning "Environment file already exists. Skipping creation."
        return
    fi
    
    cat > .env << EOF
# YO Network Validator Configuration

# Network Settings
NETWORK_ID=2025
CHAIN_ID=2025

# Node Settings
NODE_NAME=yo-validator
P2P_PORT=30303
RPC_PORT=8545
WS_PORT=8546

# Validator Settings
MINER_ENABLED=true
MINER_COINBASE=0x33D8dD5A4F871b8f78aBD7C5d82289bC026890C0

# Performance Settings
BESU_OPTS=-Xmx2g -Xms2g

# Logging
LOG_LEVEL=INFO
EOF
    
    print_success "Environment file created"
}

# Create Docker Compose file
create_docker_compose() {
    print_status "Creating Docker Compose configuration..."
    
    cat > docker-compose.yml << 'EOF'
services:
  besu-validator:
    image: hyperledger/besu:24.6.0
    container_name: yo-validator
    restart: unless-stopped
    user: "1000:1000"
    volumes:
      - validator-data:/opt/besu/data
      - ./validator/key:/opt/besu/key:ro
      - ./config/genesis.json:/config/genesis.json:ro
      - ./config/static-nodes.json:/config/static-nodes.json:ro
      - ./logs:/opt/besu/logs
    command: >
      --data-path=/opt/besu/data
      --genesis-file=/config/genesis.json
      --static-nodes-file=/config/static-nodes.json
      --node-private-key-file=/opt/besu/key
      --rpc-http-enabled
      --rpc-http-api=ETH,NET,WEB3,TXPOOL,IBFT,DEBUG,TRACE,ADMIN
      --rpc-http-cors-origins=*
      --host-allowlist=*
      --rpc-http-port=8545
      --rpc-ws-enabled
      --rpc-ws-port=8546
      --rpc-ws-api=ETH,NET,WEB3,TXPOOL,IBFT,DEBUG,TRACE
      --p2p-port=30303
      --network-id=2025
      --miner-enabled
      --miner-coinbase=0x33D8dD5A4F871b8f78aBD7C5d82289bC026890C0
      --logging=INFO
      --p2p-host=0.0.0.0
      --rpc-http-host=0.0.0.0
      --rpc-ws-host=0.0.0.0
    ports:
      - "127.0.0.1:8545:8545"  # RPC port (localhost only)
      - "127.0.0.1:8546:8546"  # WebSocket port (localhost only)
      - "30303:30303"          # P2P port (public)
    environment:
      - BESU_OPTS=${BESU_OPTS:--Xmx2g -Xms2g}
    networks:
      - yo-network

networks:
  yo-network:
    driver: bridge

volumes:
  validator-data:
    driver: local
EOF
    
    print_success "Docker Compose configuration created"
}

# Set proper permissions
set_permissions() {
    print_status "Setting proper file permissions..."
    
    chmod 600 validator/key 2>/dev/null || true
    chmod 700 validator/ 2>/dev/null || true
    chmod 644 config/*.json 2>/dev/null || true
    
    print_success "File permissions set"
}

# Main setup function
main() {
    echo "========================================"
    echo "    YO Network Validator Setup"
    echo "========================================"
    echo ""
    
    check_root
    check_requirements
    create_directories
    generate_keys
    download_network_config
    create_env_file
    create_docker_compose
    set_permissions
    
    echo ""
    echo "========================================"
    print_success "Setup completed successfully!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Review your configuration in .env file"
    echo "2. Start your validator: docker compose up -d"
    echo "3. Check logs: docker compose logs -f besu-validator"
    echo "4. Monitor sync status: ./scripts/check-sync.sh"
    echo ""
    print_warning "IMPORTANT: Backup your validator key (validator/key) in a secure location!"
    echo ""
}

# Run main function
main "$@"
