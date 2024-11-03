// spdx-license-identifier: mit
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ElectionPredictionMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GetUserBetsScript is Script {
    function run() external view {
        address marketAddress = vm.envAddress("MARKET_ADDRESS");
        address userAddress = vm.envAddress("USER_ADDRESS");
        
        ElectionPredictionMarket market = ElectionPredictionMarket(marketAddress);
        
        (
            uint8[] memory parties,
            uint256[] memory amounts,
            bool[] memory claimed
        ) = market.getUserBets(userAddress);
        
        console.log("Bets for user:", userAddress);
        for (uint256 i = 0; i < parties.length; i++) {
            console.log("Bet", i + 1);
            console.log("  Party:", parties[i] == 0 ? "Democrat" : "Republican");
	    uint256 amounti = amounts[i] / 10**18;
            console.log("  Amount:", amounti);
	    uint256 claimedi = claimed[i] ? 1 : 0;
	    console.log("  Claimed:", claimedi);
        }
    }
}

