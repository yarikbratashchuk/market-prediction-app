#!/bin/bash

# Load environment variables from .env
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

echo "Deploying to local network..."
forge script script/DeployPredictionMarket.s.sol:DeploymentScript \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --broadcast --resume
