// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IPerpMarket.sol";
import "./FundingRateLib.sol";

/// @title LiquidationKeeper — permissionless keeper for a perpetual futures market.
/// @notice Anyone can call the keeper; it (1) pushes the latest funding rate derived from
///         the mark/index premium, and (2) liquidates underwater accounts from a watchlist.
///         The keeper earns the market's liquidator bonus on each liquidation, which is the
///         economic incentive to run it. Educational reference — not audited.
contract LiquidationKeeper {
    IPerpMarket public immutable market;

    address public owner;
    uint256 public indexPrice; // 1e18 == $1.00
    uint256 public markPrice; // 1e18 == $1.00 (single-market demo)

    event FundingPushed(int256 indexed rateBps, uint256 periodSeconds);
    event Liquidated(address indexed trader, address indexed executor);
    event PricesUpdated(uint256 indexPrice, uint256 markPrice);
    event OwnerSet(address indexed owner);

    error Unauthorized();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _market, uint256 _indexPrice, uint256 _markPrice) {
        market = IPerpMarket(_market);
        owner = msg.sender;
        indexPrice = _indexPrice;
        markPrice = _markPrice;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerSet(_owner);
    }

    /// @notice Update the reference prices used for funding computation.
    /// @dev In production these come from oracle feeds; here the owner pushes them for the demo.
    function setPrices(uint256 _indexPrice, uint256 _markPrice) external onlyOwner {
        indexPrice = _indexPrice;
        markPrice = _markPrice;
        emit PricesUpdated(_indexPrice, _markPrice);
    }

    /// @notice Compute the funding rate from the current mark/index premium.
    function currentFundingRate() public view returns (int256) {
        int256 premium = FundingRateLib.premiumBps(markPrice, indexPrice);
        return FundingRateLib.computeRate(premium);
    }

    /// @notice Push one funding period to the market.
    function pushFunding(uint256 periodSeconds) external {
        int256 rate = currentFundingRate();
        market.accrueFunding(rate, periodSeconds);
        emit FundingPushed(rate, periodSeconds);
    }

    /// @notice Liquidate every underwater trader on the watchlist. Returns the count.
    /// @dev Skips healthy accounts instead of reverting, so a batch never bricks on one entry.
    function checkAndLiquidate(address[] calldata traders) external returns (uint256 liquidated) {
        uint256 n = traders.length;
        for (uint256 i = 0; i < n; i++) {
            if (market.isLiquidatable(traders[i])) {
                market.liquidate(traders[i]);
                liquidated++;
                emit Liquidated(traders[i], msg.sender);
            }
        }
    }
}
