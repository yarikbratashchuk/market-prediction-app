// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ElectionPredictionMarket.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple ERC20 token for betting
contract BetToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Election Bet Token", "EBT") {
        _mint(msg.sender, initialSupply);
    }
}

contract DeploymentScript is Script {
    // Configuration
    uint256 constant INITIAL_TOKEN_SUPPLY = 1_000_000 ether; // 1 million tokens
    uint256 constant INITIAL_DEMOCRAT_ODDS = 5000; // 50%
    string constant ELECTION_NAME = "2024 US Presidential Election";
    
    function run() external {
        // Retrieve deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy BetToken
        BetToken betToken = new BetToken(INITIAL_TOKEN_SUPPLY);
        console.log("BetToken deployed at:", address(betToken));
        
        // Deploy ElectionPredictionMarket
        ElectionPredictionMarket market = new ElectionPredictionMarket(
            address(betToken),
            ELECTION_NAME,
            INITIAL_DEMOCRAT_ODDS
        );
        console.log("ElectionPredictionMarket deployed at:", address(market));
        
        vm.stopBroadcast();
        
        // Log deployment details
        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("Network:", block.chainid);
        console.log("BetToken:", address(betToken));
        console.log("ElectionPredictionMarket:", address(market));
        console.log("Initial Token Supply:", INITIAL_TOKEN_SUPPLY / 1e18, "EBT");
        console.log("Initial Democrat Odds:", INITIAL_DEMOCRAT_ODDS / 100, "%");
        console.log("Deployer Address:", vm.addr(deployerPrivateKey));
    }
}
