// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MockPerpMarket — minimal IPerpMarket implementation for keeper unit tests.
/// @notice Liquidatability is settable directly; funding calls are recorded for assertions.
contract MockPerpMarket {
    mapping(address => bool) public liquidatable;

    int256 public lastRateBps;
    uint256 public lastPeriodSeconds;
    uint256 public fundingCalls;
    uint256 public liquidationCalls;

    function setLiquidatable(address trader, bool flag) external {
        liquidatable[trader] = flag;
    }

    function accrueFunding(int256 rateBps, uint256 periodSeconds) external {
        lastRateBps = rateBps;
        lastPeriodSeconds = periodSeconds;
        fundingCalls++;
    }

    function liquidate(address trader) external {
        require(liquidatable[trader], "MockPerpMarket: not liquidatable");
        liquidatable[trader] = false;
        liquidationCalls++;
    }

    function isLiquidatable(address trader) external view returns (bool) {
        return liquidatable[trader];
    }
}
