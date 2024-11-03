// spdx-license-identifier: mit
pragma solidity ^0.8.0;

import "forge-std/script.sol";
import "../src/electionpredictionmarket.sol";
import "@openzeppelin/contracts/token/erc20/ierc20.sol";

contract ClaimWinningsScript is Script {
    function run() external {
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address marketAddress = vm.envAddress("MARKET_ADDRESS");

        vm.startBroadcast(userPrivateKey);
        
        ElectionPredictionMarket market = ElectionPredictionMarket(marketAddress);
        market.claimWinnings();
        
        vm.stopBroadcast();
    }
}
