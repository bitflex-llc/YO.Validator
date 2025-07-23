#!/bin/bash

# YO Network Validator Sync Status Checker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if container is running
check_container() {
    if ! docker compose ps | grep -q "yo-validator.*Up"; then
        print_error "Validator container is not running"
        echo "Start it with: docker compose up -d"
        exit 1
    fi
}

# Get current block number
get_block_number() {
    local response=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        -H "Content-Type: application/json" http://localhost:8545 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "0"
        return
    fi
    
    local hex_block=$(echo "$response" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$hex_block" ]]; then
        printf "%d" "$hex_block"
    else
        echo "0"
    fi
}

# Get peer count
get_peer_count() {
    local response=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        -H "Content-Type: application/json" http://localhost:8545 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "0"
        return
    fi
    
    local hex_peers=$(echo "$response" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$hex_peers" ]]; then
        printf "%d" "$hex_peers"
    else
        echo "0"
    fi
}

# Get sync status
get_sync_status() {
    local response=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        -H "Content-Type: application/json" http://localhost:8545 2>/dev/null)
    
    if echo "$response" | grep -q '"result":false'; then
        echo "synced"
    elif echo "$response" | grep -q '"result":{'; then
        echo "syncing"
    else
        echo "unknown"
    fi
}

# Main function
main() {
    echo "========================================"
    echo "    YO Network Validator Status"
    echo "========================================"
    echo ""
    
    print_status "Checking validator status..."
    
    # Check if container is running
    check_container
    print_success "Validator container is running"
    
    # Wait a moment for RPC to be ready
    sleep 2
    
    # Get status information
    local block_number=$(get_block_number)
    local peer_count=$(get_peer_count)
    local sync_status=$(get_sync_status)
    
    echo ""
    echo "Status Information:"
    echo "==================="
    echo "Current Block:     $block_number"
    echo "Connected Peers:   $peer_count"
    echo "Sync Status:       $sync_status"
    echo ""
    
    # Provide recommendations
    if [[ "$peer_count" -eq 0 ]]; then
        print_warning "No peers connected. Check your network configuration."
    elif [[ "$peer_count" -lt 2 ]]; then
        print_warning "Only $peer_count peer(s) connected. Optimal is 2+ peers."
    else
        print_success "Good peer connectivity ($peer_count peers)"
    fi
    
    if [[ "$sync_status" == "synced" ]]; then
        print_success "Node is fully synchronized"
    elif [[ "$sync_status" == "syncing" ]]; then
        print_status "Node is synchronizing..."
    else
        print_warning "Sync status unknown. Check node logs."
    fi
    
    if [[ "$block_number" -eq 0 ]]; then
        print_warning "Block number is 0. Node may not be connected to network."
    fi
    
    echo ""
    echo "Useful Commands:"
    echo "================"
    echo "View logs:           docker compose logs -f besu-validator"
    echo "Restart validator:   docker compose restart besu-validator"
    echo "Stop validator:      docker compose down"
    echo "Update validator:    docker compose pull && docker compose up -d"
    echo ""
}

# Run main function
main "$@"
