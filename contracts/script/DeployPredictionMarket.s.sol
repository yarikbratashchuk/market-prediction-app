pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BetToken.sol";
import "../src/ElectionPredictionMarket.sol";

contract DeploymentScript is Script {
    function setUp() public {}

    function run() public {
        // Get private keys and addresses from environment
        uint256 deployerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get existing BetToken address from environment
        address betTokenAddress = vm.envAddress("TOKEN_ADDRESS");
        BetToken betToken = BetToken(betTokenAddress);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ElectionPredictionMarket with existing token
        ElectionPredictionMarket market = new ElectionPredictionMarket(
            address(betToken),
            "2024 US Presidential Election",
            5000  // 50% initial odds for Democrat
        );

        // Mint some tokens to user if needed (assuming you're the owner)
        // Note: This will only work if the deployer is the token owner
        betToken.mint(user, 1000 * 10**18);

        vm.stopBroadcast();

        // Log deployment information
        console.log("Contracts deployed:");
        console.log("Using existing BetToken at:", address(betToken));
        console.log("ElectionPredictionMarket:", address(market));
        console.log("Deployer balance (tokens):", betToken.balanceOf(deployer) / 10**18);
        console.log("User balance (tokens):", betToken.balanceOf(user) / 10**18);
    }
}
