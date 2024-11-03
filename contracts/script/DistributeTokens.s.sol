pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BetToken.sol";

contract DistributeTokens is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        // Address of your deployed BetToken
        address betTokenAddress = vm.envAddress("TOKEN_ADDRESS");
        BetToken betToken = BetToken(betTokenAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Mint additional tokens to user
        betToken.mint(user, 100 * 10**18); // Mint 1000 more tokens

        vm.stopBroadcast();

        console.log("Additional tokens minted to:", user);
    }
}
