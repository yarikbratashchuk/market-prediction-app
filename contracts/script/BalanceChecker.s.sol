// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract BalanceChecker is Script {
    function run() external {
        // Get the private key from the deployment script
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        // Check ETH balance
        uint256 ethBalance = deployer.balance;
        
        // Log the results
        console.log("Deployer Address:", deployer);
        console.log("ETH Balance:", ethBalance);
        console.log("ETH Balance (in ETH):", ethBalance / 1e18);
        
        // Calculate minimum required balance for deployment
        uint256 estimatedGas = 2938305; // from your error message
        uint256 gasPrice = 40000000001; // 40.000000001 gwei from your logs
        uint256 requiredWei = estimatedGas * gasPrice;
        
        console.log("Required balance (in ETH):", requiredWei / 1e18);
        console.log("Sufficient funds:", ethBalance >= requiredWei ? "Yes" : "No");
    }
}
