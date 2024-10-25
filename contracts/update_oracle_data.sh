#!/bin/bash

# update_oracle_data.sh
#!/bin/bash

# Load environment variables
set -a
source .env
set +a

if [ "$#" -ne 2 ]; then
    echo "Usage: ./update_oracle_data.sh <market_id> <odds>"
    echo "Example: ./update_oracle_data.sh 1 6500"
    echo "Note: odds are in basis points (e.g., 6500 = 65.00%)"
    exit 1
fi

MARKET_ID=$1
ODDS=$2
CURRENT_TIMESTAMP=$(($(date +%s) - 300))


echo "Updating oracle data..."
echo "Market ID: $MARKET_ID"
echo "Odds: $ODDS basis points"
echo "Timestamp: $CURRENT_TIMESTAMP"
echo "Oracle address: $ORACLE_ADDRESS"

# Check if caller is oracle
CALLER_ADDRESS=$(cast wallet address $PRIVATE_KEY)
echo "Caller address: $CALLER_ADDRESS"

# Update oracle data
cast send \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    $PREDICTION_MARKET_ADDRESS \
    "updateOracleData(uint256,uint256,uint256)" \
    $MARKET_ID $ODDS $CURRENT_TIMESTAMP

echo "Oracle data updated successfully!"

# Check updated odds
echo -e "\nVerifying new odds..."
cast call $PREDICTION_MARKET_ADDRESS \
    --rpc-url $RPC_URL \
    "getLatestOdds(uint256)" \
    $MARKET_ID
