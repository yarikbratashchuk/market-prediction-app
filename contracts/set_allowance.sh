#!/bin/bash

# set_allowance.sh

# Load environment variables
set -a
source .env
set +a

if [ "$#" -ne 1 ]; then
    echo "Usage: ./set_allowance.sh <amount_in_tokens>"
    echo "Example: ./set_allowance.sh 1000"
    exit 1
fi

AMOUNT_IN_TOKENS=$1
AMOUNT_IN_WEI=$(cast --to-wei $AMOUNT_IN_TOKENS)

echo "Setting allowance for Prediction Market contract..."
echo "Amount: $AMOUNT_IN_TOKENS tokens ($AMOUNT_IN_WEI wei)"
echo "Token address: $BET_TOKEN_ADDRESS"
echo "Prediction Market address: $PREDICTION_MARKET_ADDRESS"
echo "From address: $(cast wallet address $PRIVATE_KEY)"

# Set allowance
cast send \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    $BET_TOKEN_ADDRESS \
    "approve(address,uint256)" \
    $PREDICTION_MARKET_ADDRESS \
    $AMOUNT_IN_WEI

echo "Waiting for transaction to be mined..."
sleep 5

# Check new allowance
new_allowance=$(cast call $BET_TOKEN_ADDRESS \
    --rpc-url $RPC_URL \
    "allowance(address,address)" \
    $(cast wallet address $PRIVATE_KEY) \
    $PREDICTION_MARKET_ADDRESS)

new_allowance_eth=$(cast --from-wei $new_allowance)
echo -e "\nNew allowance set successfully!"
echo "Current allowance: $new_allowance wei ($new_allowance_eth tokens)"
