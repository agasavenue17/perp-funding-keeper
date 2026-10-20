// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title FundingRateLib — premium-based funding rate computation for perpetual futures.
/// @notice Funding keeps the perp price anchored to the index price: when the mark trades
///         above the index (longs crowding), the premium is positive and longs pay shorts.
library FundingRateLib {
    /// @notice Hard cap on the funding rate per period: 100 bps (1%).
    int256 internal constant MAX_FUNDING_BPS = 100;

    /// @notice Premium of mark over index, in basis points (signed).
    function premiumBps(uint256 markPrice, uint256 indexPrice) internal pure returns (int256) {
        require(indexPrice > 0, "FundingRateLib: zero index");
        return ((int256(markPrice) - int256(indexPrice)) * 10000) / int256(indexPrice);
    }

    /// @notice Funding rate for a period: the premium, clamped to +/- MAX_FUNDING_BPS.
    function computeRate(int256 premium) internal pure returns (int256) {
        if (premium > MAX_FUNDING_BPS) return MAX_FUNDING_BPS;
        if (premium < -MAX_FUNDING_BPS) return -MAX_FUNDING_BPS;
        return premium;
    }

    /// @notice Funding payment for a single position over one period (signed).
    /// @dev Positive result means the position holder pays. The market flips the sign
    ///      for shorts: longs pay when the rate is positive.
    function payment(uint256 notional, int256 rateBps) internal pure returns (int256) {
        return (int256(notional) * rateBps) / 10000;
    }
}
