pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PredictionMarket is ReentrancyGuard {
    IERC20 public betToken;

    struct Market {
        string description;
        uint256 currentOdds;
        uint256 resolutionTime;
        bool resolved;
        uint256 winningOutcome;
    }

    struct Bet {
        address bettor;
        uint256 marketId;
        uint256 amount;
        uint256 predictedOdds;
        bool isAbove;
        bool claimed;
    }

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;

    mapping(uint256 => Bet[]) public marketBets;
    mapping(address => uint256[]) public userBets;

    event MarketCreated(uint256 indexed marketId, string description, uint256 resolutionTime);
    event BetPlaced(uint256 indexed marketId, address indexed bettor, uint256 amount, uint256 predictedOdds, bool isAbove);
    event OracleDataReceived(uint256 indexed marketId, uint256 odds, uint256 timestamp);
    event MarketResolved(uint256 indexed marketId, uint256 winningOdds);
    event BetClaimed(uint256 indexed marketId, address indexed bettor, uint256 amount);

    constructor(
        address _betToken,
        string memory _description,
        uint256 _resolutionTime
    ) {
        require(_resolutionTime > block.timestamp, "Resolution time must be in the future");

        betToken = IERC20(_betToken);

        market = Market({
            description: _description,
            currentOdds: 0,
            resolutionTime: _resolutionTime,
            resolved: false,
            winningOutcome: 0
        });

        marketCount = 1;
        emit MarketCreated(0, _description, _resolutionTime);
    }

    function placeBet(uint256 _marketId, uint256 _amount, uint256 _predictedOdds, bool _isAbove) external nonReentrant {
        require(_marketId < marketCount, "Market does not exist");
        Market storage market = markets[_marketId];
        require(!market.resolved, "Market already resolved");
        require(block.timestamp < market.resolutionTime, "Market has ended");
        require(betToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Bet memory newBet = Bet({
            bettor: msg.sender,
            marketId: _marketId,
            amount: _amount,
            predictedOdds: _predictedOdds,
            isAbove: _isAbove,
            claimed: false
        });

        marketBets[_marketId].push(newBet);
        userBets[msg.sender].push(_marketId);

        emit BetPlaced(_marketId, msg.sender, _amount, _predictedOdds, _isAbove);
    }

    //function receiveOracleData(uint256 _marketId, uint256 _odds, uint256 _timestamp) external onlyOwner {
    //    require(_marketId < marketCount, "Market does not exist");
    //    Market storage market = markets[_marketId];
    //    require(!market.resolved, "Market already resolved");
    //    require(_timestamp <= market.resolutionTime, "Data is past resolution time");

    //    market.currentOdds = _odds;
    //    emit OracleDataReceived(_marketId, _odds, _timestamp);
    //}

    //function resolveMarket(uint256 _marketId, uint256 _winningOdds) external onlyOwner {
    //    require(_marketId < marketCount, "Market does not exist");
    //    Market storage market = markets[_marketId];
    //    require(!market.resolved, "Market already resolved");
    //    require(block.timestamp >= market.resolutionTime, "Market has not ended yet");

    //    market.resolved = true;
    //    market.winningOutcome = _winningOdds;

    //    emit MarketResolved(_marketId, _winningOdds);
    //}

    function claimBet(uint256 _marketId, uint256 _betIndex) external nonReentrant {
        require(_marketId < marketCount, "Market does not exist");
        Market storage market = markets[_marketId];
        require(market.resolved, "Market not resolved yet");

        Bet storage bet = marketBets[_marketId][_betIndex];
        require(bet.bettor == msg.sender, "Not the bettor");
        require(!bet.claimed, "Bet already claimed");

        bool won = (bet.isAbove && market.winningOutcome > bet.predictedOdds) ||
                   (!bet.isAbove && market.winningOutcome < bet.predictedOdds);

        bet.claimed = true;

        if (won) {
            uint256 payout = bet.amount * 2; // Simple 1:1 payout for now
            require(betToken.transfer(msg.sender, payout), "Token transfer failed");
            emit BetClaimed(_marketId, msg.sender, payout);
        }
    }

    function getMarketInfo(uint256 _marketId) external view returns (Market memory) {
        require(_marketId < marketCount, "Market does not exist");
        return markets[_marketId];
    }

    function getUserBets(address _user) external view returns (uint256[] memory) {
        return userBets[_user];
    }

    function getMarketBetsCount(uint256 _marketId) external view returns (uint256) {
        return marketBets[_marketId].length;
    }
}
