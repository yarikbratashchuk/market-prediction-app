#!/bin/bash

# Load environment variables
set -a
source .env
set +a

echo "Checking balance for address: $(cast wallet address $PRIVATE_KEY)"
balance=$(cast call $BET_TOKEN_ADDRESS \
    --rpc-url $RPC_URL \
    "balanceOf(address)" \
    $(cast wallet address $PRIVATE_KEY))

# Convert balance from wei to tokens (assuming 18 decimals)
balance_eth=$(cast --from-wei $balance)
echo "Balance: $balance wei ($balance_eth tokens)"

# Check allowance
allowance=$(cast call $BET_TOKEN_ADDRESS \
    --rpc-url $RPC_URL \
    "allowance(address,address)" \
    $(cast wallet address $PRIVATE_KEY) \
    $PREDICTION_MARKET_ADDRESS)

allowance_eth=$(cast --from-wei $allowance)
echo "Current allowance for prediction market: $allowance wei ($allowance_eth tokens)"
