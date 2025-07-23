#!/bin/bash

echo "Generating new validator keys..."

# Generate private key (64 hex characters)
PRIVATE_KEY=$(openssl rand -hex 32)

# Generate address 
ADDRESS="0x$(echo $PRIVATE_KEY | sha256sum | cut -c1-40)"

echo "Generated Validator Keys:"
echo "========================"
echo "Private Key: 0x$PRIVATE_KEY"
echo "Address: $ADDRESS"
echo ""
echo "IMPORTANT: Save these keys securely!"

# Create validator directory
mkdir -p validator
echo "0x$PRIVATE_KEY" > validator/key

# Create .env file
cat > .env << EOF
MINER_COINBASE=$ADDRESS
EOF

echo "Created .env file and validator/key"
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check dependencies
check_dependencies() {
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is required but not installed"
        exit 1
    fi
}

# Generate validator keys
generate_keys() {
    print_status "Generating new validator keys..."
    
    # Create validator directory if it doesn't exist
    mkdir -p validator
    
    # Check if key already exists
    if [[ -f "validator/key" ]]; then
        print_warning "Validator key already exists!"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Key generation cancelled"
            exit 0
        fi
    fi
    
    # Generate private key
    private_key=$(openssl rand -hex 32)
    
    # Save private key
    echo "0x${private_key}" > validator/key
    chmod 600 validator/key
    
    # Calculate public key and address (simplified for demonstration)
    # In production, you'd use proper Ethereum key derivation
    
    print_success "Validator keys generated successfully!"
    echo ""
    echo "Key Information:"
    echo "================"
    echo "Private Key File: validator/key"
    echo "Private Key:      0x${private_key}"
    echo ""
    print_warning "CRITICAL SECURITY NOTICE:"
    echo "1. NEVER share your private key with anyone"
    echo "2. Make secure backups of your validator/key file"
    echo "3. Store backups in multiple secure locations"
    echo "4. Consider using hardware security modules for production"
    echo ""
    print_warning "If you lose this key, you will lose access to your validator!"
}

# Backup existing key
backup_key() {
    if [[ -f "validator/key" ]]; then
        local backup_file="validator/key.backup.$(date +%Y%m%d_%H%M%S)"
        cp "validator/key" "$backup_file"
        print_success "Existing key backed up to: $backup_file"
    fi
}

# Main function
main() {
    echo "========================================"
    echo "    YO Network Key Generator"
    echo "========================================"
    echo ""
    
    check_dependencies
    backup_key
    generate_keys
    
    echo ""
    print_success "Key generation completed!"
    echo ""
    echo "Next steps:"
    echo "1. Securely backup your validator/key file"
    echo "2. Update your validator configuration if needed"
    echo "3. Start your validator with: docker compose up -d"
    echo ""
}

# Run main function
main "$@"
