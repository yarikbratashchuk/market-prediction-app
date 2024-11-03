#!/bin/bash

while true; do
    # Make the API request and store the response
    response=$(curl -s "https://api.elections.kalshi.com/v1/events/?single_event_per_series=false&tickers=PRES-2024")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from API"
        sleep 60
        continue
    fi
    
    # Extract the last_price for PRES-2024-KH using jq
    price=$(echo "$response" | jq -r '.events[0].markets[] | select(.ticker_name=="PRES-2024-KH") | .last_price')
    
    ./market.sh update-odds $price 
    
    # Wait for 60 seconds before next request
    sleep 60
done
