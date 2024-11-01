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
