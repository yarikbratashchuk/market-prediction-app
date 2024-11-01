#!/bin/bash

# Load environment variables from .env
source .env

# Deploy to local anvil network
echo "Deploying to local network..."
forge script script/Deploy.s.sol:DeploymentScript --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet (Sepolia)
echo "Deploying to Sepolia testnet..."
forge script script/Deploy.s.sol:DeploymentScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

# Deploy to mainnet
echo "Deploying to mainnet..."
forge script script/Deploy.s.sol:DeploymentScript --rpc-url $MAINNET_RPC_URL --broadcast --verify -vvvv
