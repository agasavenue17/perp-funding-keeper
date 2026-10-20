// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title HealthFactorLib — account health math for leveraged perpetual positions.
/// @notice Health factor is expressed in basis points of the maintenance requirement:
///         10000 == exactly at the maintenance margin, below 10000 == liquidatable.
library HealthFactorLib {
    /// @notice Maintenance margin requirement in USD (1e18) for a given notional.
    function maintenanceMargin(uint256 notional, uint256 maintenanceBps) internal pure returns (uint256) {
        return (notional * maintenanceBps) / 10000;
    }

    /// @notice Health factor in bps. Returns max int256 when there is no position.
    function healthFactor(int256 equity, uint256 notional, uint256 maintenanceBps)
        internal
        pure
        returns (int256)
    {
        if (notional == 0) return type(int256).max;
        int256 mm = int256(maintenanceMargin(notional, maintenanceBps));
        if (mm == 0) return type(int256).max;
        return (equity * 10000) / mm;
    }

    /// @notice True when equity fell below the maintenance margin requirement.
    function isLiquidatable(int256 equity, uint256 notional, uint256 maintenanceBps)
        internal
        pure
        returns (bool)
    {
        if (notional == 0) return false;
        return equity < int256(maintenanceMargin(notional, maintenanceBps));
    }
}
