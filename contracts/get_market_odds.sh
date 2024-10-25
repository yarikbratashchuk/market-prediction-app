#!/bin/bash

# Load environment variables
set -a
source .env
set +a

if [ "$#" -ne 1 ]; then
    echo "Usage: ./get_market_odds.sh <market_id>"
    echo "Example: ./get_market_odds.sh 1"
    exit 1
fi

MARKET_ID=$1

echo -e "\n📊 Market $MARKET_ID Odds Data"
echo "------------------------"

# Helper function to convert hex to decimal
hex_to_dec() {
    if [[ $1 =~ ^0x ]]; then
        echo "$1" | cast --to-dec
    else
        echo "$1"
    fi
}

# Get market details
market_details=$(cast call $PREDICTION_MARKET_ADDRESS \
    --rpc-url $RPC_URL \
    "getMarketDetails(uint256)(string,uint256,uint256,bool,bool,uint256[],uint256,uint256)" \
    $MARKET_ID)

# Split the output into lines and clean up the values
description=$(echo "$market_details" | sed -n 1p | tr -d '"')
total_pool_size=$(echo "$market_details" | sed -n 2p)
resolution_time=$(echo "$market_details" | sed -n 3p)
is_resolved=$(echo "$market_details" | sed -n 4p)
is_cancelled=$(echo "$market_details" | sed -n 5p)

# Extract pool values
pool_line=$(echo "$market_details" | sed -n 6p)
pool_0=$(echo "$pool_line" | awk '{print $1}')
pool_1=$(echo "$pool_line" | awk '{print $2}')

current_odds=$(echo "$market_details" | sed -n 7p)
last_update=$(echo "$market_details" | sed -n 8p)

echo "Description: $description"
echo -e "\n💰 Pool Sizes:"

# Convert and display pool sizes
if [ ! -z "$total_pool_size" ]; then
    total_pool_dec=$(hex_to_dec "$total_pool_size")
    total_pool_eth=$(cast --from-wei "$total_pool_dec")
    echo "Total Pool: $total_pool_eth tokens"
fi

if [ ! -z "$pool_0" ] && [ ! -z "$pool_1" ]; then
    pool_0_dec=$(hex_to_dec "$pool_0")
    pool_1_dec=$(hex_to_dec "$pool_1")
    pool_0_eth=$(cast --from-wei "$pool_0_dec")
    pool_1_eth=$(cast --from-wei "$pool_1_dec")
    
    echo "No (0) Pool: $pool_0_eth tokens"
    echo "Yes (1) Pool: $pool_1_eth tokens"
fi

echo -e "\n⏰ Market Status:"
if [ ! -z "$resolution_time" ]; then
    resolution_dec=$(hex_to_dec "$resolution_time")
    if [ "$resolution_dec" -gt "0" ]; then
        echo "Resolution Date: $(date -r "$resolution_dec" "+%Y-%m-%d %H:%M:%S")"
    else
        echo "Resolution Date: Not set"
    fi
fi

echo "Resolved: $is_resolved"
echo "Cancelled: $is_cancelled"

# Get latest oracle data
echo -e "\n🔮 Latest Oracle Data:"
odds_data=$(cast call $PREDICTION_MARKET_ADDRESS \
    --rpc-url $RPC_URL \
    "getLatestOdds(uint256)(uint256,uint256)" \
    $MARKET_ID)

odds=$(echo "$odds_data" | sed -n 1p)
timestamp=$(echo "$odds_data" | sed -n 2p)

if [ ! -z "$odds" ]; then
    odds_dec=$(hex_to_dec "$odds")
    if [ "$odds_dec" != "0" ]; then
        formatted_odds=$(echo "scale=2; $odds_dec / 100" | bc)
        echo "Latest Odds: ${formatted_odds}%"
    else
        echo "Latest Odds: Not set"
    fi
fi

if [ ! -z "$timestamp" ]; then
    timestamp_dec=$(hex_to_dec "$timestamp")
    if [ "$timestamp_dec" -gt "0" ]; then
        echo "Timestamp: $(date -r "$timestamp_dec" "+%Y-%m-%d %H:%M:%S")"
    else
        echo "Timestamp: Not set"
    fi
fi

echo -e "\n------------------------"

# Get historical odds count
historical_count=$(cast call $PREDICTION_MARKET_ADDRESS \
    --rpc-url $RPC_URL \
    "getHistoricalOddsCount(uint256)(uint256)" \
    $MARKET_ID)

historical_count=$(hex_to_dec "$historical_count")

if [ "$historical_count" -gt "0" ]; then
    echo -e "\n📜 Historical Odds Data:"
    echo "Number of historical entries: $historical_count"
    
    # Display last 5 historical entries or less if fewer exist
    display_count=5
    if [ "$historical_count" -lt "$display_count" ]; then
        display_count=$historical_count
    fi
    
    echo "Last $display_count entries:"
    for ((i=historical_count-1; i>=historical_count-display_count && i>=0; i--)); do
        historical_data=$(cast call $PREDICTION_MARKET_ADDRESS \
            --rpc-url $RPC_URL \
            "getHistoricalOdds(uint256,uint256)(uint256,uint256)" \
            $MARKET_ID $i)
            
        hist_odds=$(echo "$historical_data" | sed -n 1p)
        hist_timestamp=$(echo "$historical_data" | sed -n 2p)
        
        if [ ! -z "$hist_odds" ]; then
            hist_odds_dec=$(hex_to_dec "$hist_odds")
            if [ "$hist_odds_dec" != "0" ]; then
                formatted_hist_odds=$(echo "scale=2; $hist_odds_dec / 100" | bc)
                echo -n "Entry $i: ${formatted_hist_odds}%"
                
                if [ ! -z "$hist_timestamp" ]; then
                    hist_timestamp_dec=$(hex_to_dec "$hist_timestamp")
                    if [ "$hist_timestamp_dec" -gt "0" ]; then
                        echo " ($(date -r "$hist_timestamp_dec" "+%Y-%m-%d %H:%M:%S"))"
                    else
                        echo ""
                    fi
                fi
            fi
        fi
    done
fi
