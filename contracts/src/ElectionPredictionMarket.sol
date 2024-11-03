// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ElectionPredictionMarket is ReentrancyGuard, Ownable {
    IERC20 public immutable betToken;
    
    // November 5, 2024, 23:59:59 UTC
    uint256 public constant ELECTION_END_TIME = 1730764800;
    
    struct Market {
        string electionName;
        uint256 totalPoolSize;
        bool isResolved;
        uint8 winner;              // 0 = Democrat, 1 = Republican
        mapping(uint8 => uint256) partyPools;
        uint256 democratOdds;      // Represented in basis points (1/10000)
        uint256 republicanOdds;    // e.g., 5000 = 50% probability
        uint256 lastOddsUpdate;
    }
    
    struct Bet {
        uint8 party;
        uint256 amount;
        bool claimed;
    }
    
    Market public electionMarket;
    mapping(address => Bet[]) public userBets;
    
    event BetPlaced(address indexed bettor, uint8 party, uint256 amount);
    event MarketResolved(uint8 winner);
    event WinningsClaimed(address indexed bettor, uint256 amount);
    event OddsUpdated(uint256 democratOdds, uint256 republicanOdds);
    
    constructor(
        address _betToken,
        string memory _electionName,
        uint256 _initialDemocratOdds
    ) Ownable(msg.sender) {
        require(_betToken != address(0), "Invalid token address");
        require(_initialDemocratOdds <= 10000, "Odds must be <= 10000");
        
        betToken = IERC20(_betToken);
        
        // Initialize market
        electionMarket.electionName = _electionName;
        electionMarket.democratOdds = _initialDemocratOdds;
        electionMarket.republicanOdds = 10000 - _initialDemocratOdds;
        electionMarket.lastOddsUpdate = block.timestamp;
        
        emit OddsUpdated(_initialDemocratOdds, 10000 - _initialDemocratOdds);
    }
    
    function updateOdds(uint256 _democratOdds) external onlyOwner {
        require(_democratOdds <= 10000, "Odds must be <= 10000");
        require(block.timestamp < ELECTION_END_TIME, "Election ended");
        require(!electionMarket.isResolved, "Market already resolved");
        
        electionMarket.democratOdds = _democratOdds;
        electionMarket.republicanOdds = 10000 - _democratOdds;
        electionMarket.lastOddsUpdate = block.timestamp;
        
        emit OddsUpdated(_democratOdds, 10000 - _democratOdds);
    }
    
    function placeBet(uint8 _party, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Bet amount must be positive");
        require(_party <= 1, "Invalid party choice");
        require(block.timestamp < ELECTION_END_TIME, "Betting period ended");
        require(!electionMarket.isResolved, "Market already resolved");
        
        require(betToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        electionMarket.totalPoolSize += _amount;
        electionMarket.partyPools[_party] += _amount;
        
        userBets[msg.sender].push(Bet({
            party: _party,
            amount: _amount,
            claimed: false
        }));
        
        emit BetPlaced(msg.sender, _party, _amount);
    }
    
    function resolveMarket(uint8 _winner) external onlyOwner {
        require(block.timestamp >= ELECTION_END_TIME, "Election not ended");
        require(!electionMarket.isResolved, "Market already resolved");
        
        electionMarket.isResolved = true;
        electionMarket.winner = _winner;
        
        emit MarketResolved(_winner);
    }
    
    function claimWinnings() external nonReentrant {
        require(electionMarket.isResolved, "Market not resolved");
    
        uint256 totalWinnings = 0;
        Bet[] storage bets = userBets[msg.sender];
    
        uint256 winningPool = electionMarket.partyPools[electionMarket.winner];
        uint256 losingPool = electionMarket.totalPoolSize - winningPool;
    
        for (uint256 i = 0; i < bets.length; i++) {
            if (!bets[i].claimed && bets[i].party == electionMarket.winner) {
                // Calculate user's share of the losing pool based on their proportion of winning pool
                uint256 winnerShare = (bets[i].amount * losingPool) / winningPool;
                // Total winnings = original bet + share of losing pool
                uint256 winnings = bets[i].amount + winnerShare;
    
                totalWinnings += winnings;
                bets[i].claimed = true;
            }
        }
    
        require(totalWinnings > 0, "No winnings to claim");
        require(betToken.transfer(msg.sender, totalWinnings), "Token transfer failed");
    
        emit WinningsClaimed(msg.sender, totalWinnings);
    }
    
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
    ) {
        return (
            electionMarket.electionName,
            ELECTION_END_TIME,
            electionMarket.totalPoolSize,
            electionMarket.isResolved,
            electionMarket.partyPools[0],
            electionMarket.partyPools[1],
            electionMarket.democratOdds,
            electionMarket.republicanOdds,
            electionMarket.lastOddsUpdate
        );
    }
    
    function getUserBets(address _user) external view returns (
        uint8[] memory parties,
        uint256[] memory amounts,
        bool[] memory claimed
    ) {
        Bet[] storage bets = userBets[_user];
        parties = new uint8[](bets.length);
        amounts = new uint256[](bets.length);
        claimed = new bool[](bets.length);
        
        for (uint256 i = 0; i < bets.length; i++) {
            parties[i] = bets[i].party;
            amounts[i] = bets[i].amount;
            claimed[i] = bets[i].claimed;
        }
        
        return (parties, amounts, claimed);
    }
}
