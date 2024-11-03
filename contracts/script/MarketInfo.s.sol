// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@bokkypoobah/BokkyPooBahsDateTimeLibrary.sol";

interface IPredictionMarket {
    function getMarketInfo() external view returns (
        string memory electionName,
        uint256 endTime,
        uint256 totalPoolSize,
        bool isResolved,
        uint256 democratPool,
        uint256 republicanPool,
        uint256 democratOdds,
        uint256 republicanOdds,
        uint256 lastOddsUpdate
    );
}

contract MarketInfoScript is Script {
    function formatBasisPoints(uint256 bps) internal pure returns (string memory) {
        uint256 whole = bps / 100;
        uint256 decimal = bps % 100;
        return string(abi.encodePacked(
            toString(whole),
            ".",
            decimal < 10 ? "0" : "",
            toString(decimal),
            "%"
        ));
    }

    function formatEther(uint256 amount) internal pure returns (string memory) {
        uint256 whole = amount / 1e18;
        uint256 decimal = (amount % 1e18) / 1e16; // Get 2 decimal places
        return string(abi.encodePacked(
            toString(whole),
            ".",
            decimal < 10 ? "0" : "",
            toString(decimal),
            " BET"
        ));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function run() external view {
        address contractAddress = vm.envAddress("MARKET_ADDRESS");
        IPredictionMarket market = IPredictionMarket(contractAddress);
        
        (
            string memory electionName,
            uint256 endTime,
            uint256 totalPoolSize,
            bool isResolved,
            uint256 democratPool,
            uint256 republicanPool,
            uint256 democratOdds,
            uint256 republicanOdds,
            uint256 lastOddsUpdate
        ) = market.getMarketInfo();

        console2.log("\n=== Market Information ===");
        console2.log("------------------------");
	console2.log("Election Name:", electionName);
        console2.log("Status:", isResolved ? "Resolved" : "Active");
	(uint yeart, uint montht, uint dayt) = BokkyPooBahsDateTimeLibrary.timestampToDate(endTime);
        console2.log("End Time: %s-%s-%s",
            toString(yeart),
	    toString(montht),
	    toString(dayt)
        );

	(uint yeard, uint monthd, uint dayd) = BokkyPooBahsDateTimeLibrary.timestampToDate(lastOddsUpdate);
        console2.log("Last Odds Updated: %s-%s-%s",
	    toString(yeard),	
	    toString(monthd),
	    toString(dayd)
        );
        console2.log("");
        
        console2.log("Current Odds");
        console2.log("------------");
        console2.log("Democrat:", formatBasisPoints(democratOdds));
        console2.log("Republican:", formatBasisPoints(republicanOdds));
        console2.log("");
        
        console2.log("Pool Information");
        console2.log("----------------");
        console2.log("Total Pool:", formatEther(totalPoolSize));
        console2.log("Democrat Pool:", formatEther(democratPool));
        console2.log("Republican Pool:", formatEther(republicanPool));
        
        // Calculate and display implied probabilities if pools are not empty
        if (totalPoolSize > 0) {
            console2.log("");
            console2.log("Implied Probabilities from Pool Sizes");
            console2.log("------------------------------------");
            uint256 demImplied = (democratPool * 10000) / totalPoolSize;
            uint256 repImplied = (republicanPool * 10000) / totalPoolSize;
            console2.log("Democrat:", formatBasisPoints(demImplied));
            console2.log("Republican:", formatBasisPoints(repImplied));
        }
    }
}
