#!/bin/bash

# 1. First build with Foundry
forge build --force

# 2. Create a script to extract ABI and bytecode for both contracts
cat > extract_abi.js << EOL
const fs = require('fs');
const path = require('path');

// Process BetToken
const betTokenJson = JSON.parse(fs.readFileSync('./out/BetToken.sol/BetToken.json', 'utf8'));
fs.writeFileSync(
    'BetToken.abi',
    JSON.stringify(betTokenJson.abi)
);
fs.writeFileSync(
    'BetToken.bin',
    betTokenJson.bytecode.object.substring(2)  // Remove '0x' prefix
);

// Process ElectionPredictionMarket
const marketJson = JSON.parse(fs.readFileSync('./out/ElectionPredictionMarket.sol/ElectionPredictionMarket.json', 'utf8'));
fs.writeFileSync(
    'ElectionPredictionMarket.abi',
    JSON.stringify(marketJson.abi)
);
fs.writeFileSync(
    'ElectionPredictionMarket.bin',
    marketJson.bytecode.object.substring(2)  // Remove '0x' prefix
);
EOL

# 3. Run the extraction script
node extract_abi.js

# 4. Generate Go bindings for both contracts
# Generate BetToken bindings
abigen --abi BetToken.abi \
       --bin BetToken.bin \
       --pkg prediction \
       --type BetToken \
       --out ../../artela-rollkit/contracts/generated/bet_token.go

# Generate ElectionPredictionMarket bindings
abigen --abi ElectionPredictionMarket.abi \
       --bin ElectionPredictionMarket.bin \
       --pkg prediction \
       --type ElectionPredictionMarket \
       --out ../../artela-rollkit/contracts/generated/election_market.go

echo "Go bindings generated successfully!"
