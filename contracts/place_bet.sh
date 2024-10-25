#!/bin/bash

# Load environment variables
set -a
source .env
set +a

if [ "$#" -ne 3 ]; then
    echo "Usage: ./place_bet.sh <market_id> <outcome> <amount_in_tokens>"
    echo "Example: ./place_bet.sh 1 1 10"
    exit 1
fi

MARKET_ID=$1
OUTCOME=$2
AMOUNT_IN_TOKENS=$3

# Convert amount to wei
AMOUNT_IN_WEI=$(cast --to-wei $AMOUNT_IN_TOKENS)

echo "Approving tokens..."
cast send \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    $BET_TOKEN_ADDRESS \
    "approve(address,uint256)" \
    $PREDICTION_MARKET_ADDRESS \
    $AMOUNT_IN_WEI

echo "Placing bet..."
echo "Market ID: $MARKET_ID"
echo "Outcome: $OUTCOME (0=No, 1=Yes)"
echo "Amount: $AMOUNT_IN_TOKENS tokens ($AMOUNT_IN_WEI wei)"

cast send \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    $PREDICTION_MARKET_ADDRESS \
    "placeBet(uint256,uint8,uint256)" \
    $MARKET_ID $OUTCOME $AMOUNT_IN_WEI

echo "Bet placed successfully!"
