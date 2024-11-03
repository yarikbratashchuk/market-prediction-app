// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ElectionPredictionMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// UpdateOdds.s.sol
contract UpdateOddsScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address marketAddress = vm.envAddress("CONTRACT_ADDRESS");
        uint256 newDemocratOdds = 4000; // in basis points (e.g., 5500 for 55%)

        vm.startBroadcast(deployerPrivateKey);
        
        ElectionPredictionMarket market = ElectionPredictionMarket(marketAddress);
        market.updateOdds(newDemocratOdds);
        
        vm.stopBroadcast();
    }
}
