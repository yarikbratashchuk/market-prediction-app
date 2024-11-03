#!/bin/bash

# Load environment variables
source .env

# Ensure required environment variables are set
if [ -z "$OWNER_PRIVATE_KEY" ] || [ -z "$USER_PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY and USER_PRIVATE_KEY must be set in .env"
    exit 1
fi

# Helper function for wei conversion
to_wei() {
    echo "$1 * 10^18" | bc
}

# Helper function for basis points conversion
to_bps() {
    echo "$1 * 100" | bc
}

# Helper function to convert wei to ETH
from_wei() {
    echo "scale=18; $1 / 10^18" | bc
}

# Helper function to convert timestamp to date
format_date() {
    date "@$1" "+%Y-%m-%d %H:%M:%S UTC"
}

# Helper function to format basis points to percentage
format_percentage() {
    echo "scale=2; $1 / 100" | bc
}

update_odds() {
    local democrat_probability=$1
    
    # Convert probability to basis points (e.g., 50.5 -> 5050)
    local bps=$(to_bps $democrat_probability)
    
    echo "Updating odds to $democrat_probability% ($bps basis points) for Democrats..."
    
    cast send --private-key $OWNER_PRIVATE_KEY \
        --rpc-url $RPC_URL \
        $MARKET_ADDRESS \
        "updateOdds(uint256)" \
        $bps
}

resolve_market() {
    echo "Resolving market based on current odds..."

    local winner=$1
    
    cast send --private-key $OWNER_PRIVATE_KEY \
        --rpc-url $RPC_URL \
        $MARKET_ADDRESS \
        "resolveMarket(uint8)" \
	$winner
}

place_bet() {
    local party=$1  # 0 for Democrat, 1 for Republican
    local amount=$2 # in ETH/tokens
    local amount_wei=$(to_wei $amount)
    
    echo "Approving token spend..."
    cast send --private-key $USER_PRIVATE_KEY \
        --rpc-url $RPC_URL \
        $TOKEN_ADDRESS \
        "approve(address,uint256)" \
        $MARKET_ADDRESS \
        $amount_wei
        
    echo "Placing bet of $amount tokens on party $party..."
    cast send --private-key $USER_PRIVATE_KEY \
        --rpc-url $RPC_URL \
        $MARKET_ADDRESS \
        "placeBet(uint8,uint256)" \
        $party \
        $amount_wei
}

get_market_info() {
    forge script script/MarketInfo.s.sol  --rpc-url $RPC_URL --private-key=$USER_PRIVATE_KEY
}

claim_winnings() {
    echo "Claiming winnings..."
    
    cast send --private-key $USER_PRIVATE_KEY \
        --rpc-url $RPC_URL \
        $MARKET_ADDRESS \
        "claimWinnings()"
}

# Main script logic
case "$1" in
    "update-odds")
        if [ -z "$2" ]; then
            echo "Usage: $0 update-odds <democrat_probability>"
            echo "Example: $0 update-odds 52.5"
            exit 1
        fi
        update_odds $2
        ;;
        
    "resolve")
        resolve_market $2
        ;;
        
    "bet")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 bet <party> <amount>"
            echo "Example: $0 bet 0 1.5"
            echo "Party: 0 for Democrat, 1 for Republican"
            exit 1
        fi
        place_bet $2 $3
        ;;
        
    "info")
        get_market_info
        ;;
        
    "claim")
        claim_winnings
        ;;
        
    *)
        echo "Usage: $0 <command> [arguments]"
        echo "Commands:"
        echo "  update-odds <democrat_probability> - Update odds (e.g., 52.5 for 52.5%)"
        echo "  resolve                           - Resolve the market"
        echo "  bet <party> <amount>              - Place a bet (party: 0=Democrat, 1=Republican)"
        echo "  info                              - Get market information"
        echo "  claim                             - Claim winnings"
        exit 1
        ;;
esac
