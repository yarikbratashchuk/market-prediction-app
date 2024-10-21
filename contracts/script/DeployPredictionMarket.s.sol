// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/BetToken.sol";
import "../src/prediction_market.sol";

contract DeployPredictionMarket is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy BetToken
        uint256 initialSupply = 1000000 * 10**18; // 1 million tokens with 18 decimals
        BetToken betToken = new BetToken(initialSupply);
        console.log("BetToken deployed at:", address(betToken));

        // Deploy PredictionMarket with a market
        string memory description = "Will it rain tomorrow?";
        uint256 resolutionTime = block.timestamp + 1 days; // 24 hours from now
        PredictionMarket predictionMarket = new PredictionMarket(
            address(betToken),
            description,
            resolutionTime
        );
        console.log("PredictionMarket deployed at:", address(predictionMarket));
        
        vm.stopBroadcast();
    }
}
