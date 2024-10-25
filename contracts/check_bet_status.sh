#!/bin/bash

# Load environment variables
set -a
source .env
set +a

if [ "$#" -ne 1 ]; then
    echo "Usage: ./check_bet_status.sh <market_id>"
    echo "Example: ./check_bet_status.sh 1"
    exit 1
fi

MARKET_ID=$1
USER_ADDRESS=$(cast wallet address $PRIVATE_KEY)

echo "Checking bet status for market $MARKET_ID"
echo "User address: $USER_ADDRESS"

# Get number of bets for this market
bet_count=$(cast call $PREDICTION_MARKET_ADDRESS \
    --rpc-url $RPC_URL \
    "getUserBetCount(uint256,address)" \
    $MARKET_ID $USER_ADDRESS)

echo "Number of bets in this market: $bet_count"

# Get market details
echo -e "\nMarket Details:"
cast call $PREDICTION_MARKET_ADDRESS \
    --rpc-url $RPC_URL \
    "getMarketDetails(uint256)" \
    $MARKET_ID
