import "forge-std/Script.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BetToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Bet Token", "BET") Ownable(msg.sender) {
        // Mint initial supply to the deployer
        // Note: ERC20 uses 18 decimals by default
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
