// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IPerpMarket — minimal surface a keeper needs from a perpetual margin market.
/// @notice Matches the interface of `perp-margin-engine`'s PerpMarket (sister repo).
interface IPerpMarket {
    /// @notice Accrue a funding rate over every open position.
    /// @param rateBps Funding rate in basis points. Positive => longs pay shorts.
    /// @param periodSeconds Length of the funding period the rate applies to.
    function accrueFunding(int256 rateBps, uint256 periodSeconds) external;

    /// @notice Close an underwater position; caller earns the liquidator bonus.
    function liquidate(address trader) external;

    /// @notice True when the trader's equity is below the maintenance margin.
    function isLiquidatable(address trader) external view returns (bool);
}
