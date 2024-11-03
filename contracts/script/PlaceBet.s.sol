// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BetToken.sol";
import "../src/ElectionPredictionMarket.sol";

contract PlaceBetScript is Script {
    function setUp() public {}

    function run() public {
        // Get user's private key
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        // Get deployed contract addresses from environment
        address marketAddress = vm.envAddress("MARKET_ADDRESS");
        address betTokenAddress = vm.envAddress("TOKEN_ADDRESS");

        // Create contract instances
        ElectionPredictionMarket market = ElectionPredictionMarket(marketAddress);
        BetToken betToken = BetToken(betTokenAddress);

        // Start broadcasting as user
        vm.startBroadcast(userPrivateKey);

        // Amount to bet (100 tokens)
        uint256 betAmount = 100 * 10**18;

        // Check and log initial balances
        uint256 initialBalance = betToken.balanceOf(user);
        console.log("Initial token balance:", initialBalance / 10**18);

        // Approve market to spend tokens (if not already approved)
        betToken.approve(marketAddress, betAmount);
        
        // Place bet (0 for Democrat, 1 for Republican)
        uint8 party = 0; // Betting on Democrat
        market.placeBet(party, betAmount);

        // Log final balance
        uint256 finalBalance = betToken.balanceOf(user);
        console.log("Final token balance:", finalBalance / 10**18);
        
        // Get market info to verify bet was placed
        (
            string memory electionName,
            ,  // endTime
            uint256 totalPoolSize,
            bool isResolved,
            uint256 democratPool,
            uint256 republicanPool,
            uint256 democratOdds,
            uint256 republicanOdds,
            
        ) = market.getMarketInfo();

        console.log("\nMarket Status After Bet:");
        console.log("Election:", electionName);
        console.log("Total Pool Size:", totalPoolSize / 10**18);
        console.log("Democrat Pool:", democratPool / 10**18);
        console.log("Republican Pool:", republicanPool / 10**18);
        console.log("Democrat Odds:", democratOdds);
        console.log("Republican Odds:", republicanOdds);
        console.log("Is Resolved:", isResolved);

        vm.stopBroadcast();
    }
}
