// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/BetToken.sol";
import "../src/PredictionMarket.sol";

contract DeployPredictionMarket is Script {
    function setUp() public {}

    function run() public {
        // Load configuration from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        
        // Set defaults for optional configurations
        uint256 initialTokenSupply;
        uint256 marketResolutionDays;
        uint256 updateInterval;

        // Try to load from environment, use defaults if not set
        try vm.envUint("INITIAL_TOKEN_SUPPLY") returns (uint256 value) {
            initialTokenSupply = value;
        } catch {
            initialTokenSupply = 1000000 * 10**18; // 1 million tokens with 18 decimals
        }

        try vm.envUint("MARKET_RESOLUTION_DAYS") returns (uint256 value) {
            marketResolutionDays = value;
        } catch {
            marketResolutionDays = 180; // 180 days default
        }

        try vm.envUint("UPDATE_INTERVAL") returns (uint256 value) {
            updateInterval = value;
        } catch {
            updateInterval = 5 minutes; // 5 minutes default
        }

        vm.startBroadcast(deployerPrivateKey);

        // Deploy BetToken
        console.log("Deploying BetToken with initial supply:", initialTokenSupply);
        BetToken betToken = new BetToken(initialTokenSupply);
        console.log("BetToken deployed at:", address(betToken));

        // Deploy PredictionMarket
        console.log("Deploying PredictionMarket...");
        PredictionMarket predictionMarket = new PredictionMarket(
            address(betToken),
            deployerAddress  // Set deployer as initial owner
        );
        console.log("PredictionMarket deployed at:", address(predictionMarket));

        // Configure oracle
        console.log("Setting oracle address:", oracleAddress);
        predictionMarket.setOracle(oracleAddress);

        // Create initial markets
        string[] memory marketDescriptions = new string[](2);
        marketDescriptions[0] = "US Presidential Election 2024 - Democratic Party Victory";
        marketDescriptions[1] = "US Presidential Election 2024 - Republican Party Victory";

        console.log("Creating initial markets...");
        for (uint i = 0; i < marketDescriptions.length; i++) {
            uint256 resolutionTime = block.timestamp + (marketResolutionDays * 1 days);
            predictionMarket.createMarket(
                marketDescriptions[i],
                resolutionTime,
                updateInterval
            );
            console.log("Created market:", marketDescriptions[i]);
            console.log("Resolution time:", resolutionTime);
        }

        // Grant initial token allowance to the prediction market
        console.log("Setting initial token allowance...");
        uint256 allowanceAmount = initialTokenSupply / 2; // 50% of total supply
        betToken.approve(address(predictionMarket), allowanceAmount);
        console.log("Approved prediction market to spend:", allowanceAmount);

        // Transfer some initial tokens to the deployer if needed
        if (deployerAddress != address(this)) {
            uint256 deployerAmount = initialTokenSupply / 10; // 10% of total supply
            betToken.transfer(deployerAddress, deployerAmount);
            console.log("Transferred initial tokens to deployer:", deployerAmount);
        }

        vm.stopBroadcast();

        // Log final deployment summary
        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("BetToken:", address(betToken));
        console.log("PredictionMarket:", address(predictionMarket));
        console.log("Oracle:", oracleAddress);
        console.log("Update Interval:", updateInterval);
        console.log("Number of Markets Created:", marketDescriptions.length);
    }
}
