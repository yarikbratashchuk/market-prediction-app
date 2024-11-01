#!/bin/bash

# Verify required paths and files
# Check if Foundry output directory exists
if [ ! -d "./out" ]; then
    echo "Error: Foundry output directory './out' not found"
    exit 1
fi

# Check if contract files exist
if [ ! -f "./out/BetToken.sol/BetToken.json" ]; then
    echo "Error: BetToken contract output not found"
    exit 1
fi

if [ ! -f "./out/ElectionPredictionMarket.sol/ElectionPredictionMarket.json" ]; then
    echo "Error: ElectionPredictionMarket contract output not found"
    exit 1
fi

# Check if target directory exists
if [ ! -d "../../artela-rollkit/contracts/generated" ]; then
    echo "Creating target directory..."
    mkdir -p "../../artela-rollkit/contracts/generated"
fi

echo "All paths verified successfully!"
