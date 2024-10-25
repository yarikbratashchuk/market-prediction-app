// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PredictionMarket is ReentrancyGuard, Ownable, Pausable {
    IERC20 public immutable betToken;

    struct OracleData {
        uint256 odds;
        uint256 timestamp;
    }

    struct Market {
        string description;
        uint256 totalPoolSize;
        uint256 resolutionTime;
        bool resolved;
        uint8 winningOutcome;
        mapping(uint8 => uint256) outcomePools;
        bool cancelled;
        OracleData[] historicalOdds;
        OracleData currentOdds;
        uint256 lastUpdateBlock;
        uint256 minimumUpdateInterval;
    }

    struct UserBet {
        uint8 outcome;
        uint256 amount;
        uint256 oddsAtBet;
        bool claimed;
    }

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;

    mapping(uint256 => mapping(address => UserBet[])) public userBets;

    address public oracle;
    uint256 public constant MIN_UPDATE_INTERVAL = 1 minutes;
    uint256 public constant MAX_HISTORICAL_DATA_POINTS = 1000;

    event MarketCreated(uint256 indexed marketId, string description, uint256 resolutionTime);
    event BetPlaced(uint256 indexed marketId, address indexed bettor, uint8 outcome, uint256 amount, uint256 oddsAtBet);
    event MarketResolved(uint256 indexed marketId, uint8 winningOutcome);
    event MarketCancelled(uint256 indexed marketId);
    event BetClaimed(uint256 indexed marketId, address indexed bettor, uint256 amount);
    event OracleUpdated(uint256 indexed marketId, uint256 odds, uint256 timestamp);
    event OracleAddressUpdated(address newOracle);

    modifier onlyOracle() {
        require(msg.sender == oracle, "Caller is not the oracle");
        _;
    }

    constructor(address _betToken, address initialOwner)
        Ownable(initialOwner)
        Pausable()
    {
        require(_betToken != address(0), "Invalid token address");
        betToken = IERC20(_betToken);
    }
    
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracle = _oracle;
        emit OracleAddressUpdated(_oracle);
    }
    
    function createMarket(
        string memory _description,
        uint256 _resolutionTime,
        uint256 _minimumUpdateInterval
    ) external onlyOwner {
        require(_resolutionTime > block.timestamp + 1 days, "Resolution time too soon");
        require(_resolutionTime < block.timestamp + 365 days, "Resolution time too far");
        require(_minimumUpdateInterval >= MIN_UPDATE_INTERVAL, "Update interval too short");
        
        uint256 marketId = marketCount++;
        Market storage market = markets[marketId];
        market.description = _description;
        market.resolutionTime = _resolutionTime;
        market.minimumUpdateInterval = _minimumUpdateInterval;
        
        emit MarketCreated(marketId, _description, _resolutionTime);
    }
    
    function updateOracleData(
        uint256 _marketId,
        uint256 _odds,
        uint256 _timestamp
    ) external onlyOracle whenNotPaused {
        Market storage market = markets[_marketId];
        require(!market.resolved && !market.cancelled, "Market no longer active");
        require(block.timestamp >= market.lastUpdateBlock + market.minimumUpdateInterval, "Too soon to update");
        require(_timestamp <= block.timestamp, "Future timestamp not allowed");
        
        // Store historical data
        if (market.historicalOdds.length < MAX_HISTORICAL_DATA_POINTS) {
            market.historicalOdds.push(market.currentOdds);
        }
        
        // Update current odds
        market.currentOdds = OracleData({
            odds: _odds,
            timestamp: _timestamp
        });
        market.lastUpdateBlock = block.timestamp;
        
        emit OracleUpdated(_marketId, _odds, _timestamp);
    }
    
    function placeBet(
        uint256 _marketId,
        uint8 _outcome,
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        require(_amount > 0, "Bet amount must be positive");
        require(_outcome <= 1, "Invalid outcome");
        
        Market storage market = markets[_marketId];
        require(!market.resolved && !market.cancelled, "Market no longer active");
        require(block.timestamp < market.resolutionTime, "Market has ended");
        
        require(betToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        // Update pool sizes
        market.totalPoolSize += _amount;
        market.outcomePools[_outcome] += _amount;
        
        // Record user bet with current odds
        userBets[_marketId][msg.sender].push(UserBet({
            outcome: _outcome,
            amount: _amount,
            oddsAtBet: market.currentOdds.odds,
            claimed: false
        }));
        
        emit BetPlaced(_marketId, msg.sender, _outcome, _amount, market.currentOdds.odds);
    }
    
    // View functions for oracle data
    function getLatestOdds(uint256 _marketId) external view returns (uint256 odds, uint256 timestamp) {
        Market storage market = markets[_marketId];
        return (market.currentOdds.odds, market.currentOdds.timestamp);
    }
    
    function getHistoricalOdds(uint256 _marketId, uint256 _index) external view returns (uint256 odds, uint256 timestamp) {
        Market storage market = markets[_marketId];
        require(_index < market.historicalOdds.length, "Index out of bounds");
        OracleData memory data = market.historicalOdds[_index];
        return (data.odds, data.timestamp);
    }
    
    function getHistoricalOddsCount(uint256 _marketId) external view returns (uint256) {
        return markets[_marketId].historicalOdds.length;
    }
    
    function getMarketDetails(uint256 _marketId) external view returns (
        string memory description,
        uint256 totalPoolSize,
        uint256 resolutionTime,
        bool resolved,
        bool cancelled,
        uint256[] memory outcomePools,
        uint256 currentOdds,
        uint256 lastUpdateBlock
    ) {
        Market storage market = markets[_marketId];
        outcomePools = new uint256[](2);
        outcomePools[0] = market.outcomePools[0];
        outcomePools[1] = market.outcomePools[1];
        
        return (
            market.description,
            market.totalPoolSize,
            market.resolutionTime,
            market.resolved,
            market.cancelled,
            outcomePools,
            market.currentOdds.odds,
            market.lastUpdateBlock
        );
    }
    
    // Rest of the contract functions (resolveMarket, cancelMarket, claimBet) remain the same...
}
