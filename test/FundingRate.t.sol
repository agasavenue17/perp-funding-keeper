// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../src/FundingRateLib.sol";
import "../src/HealthFactorLib.sol";

contract FundingRateTest {
    // -- premium / rate computation ------------------------------------------

    function test_PremiumBps() public pure {
        // mark 2100 vs index 2000 => +5% => 500 bps
        require(FundingRateLib.premiumBps(2100e18, 2000e18) == 500, "positive premium");
        // mark 1900 vs index 2000 => -5% => -500 bps
        require(FundingRateLib.premiumBps(1900e18, 2000e18) == -500, "negative premium");
        // mark == index => 0
        require(FundingRateLib.premiumBps(2000e18, 2000e18) == 0, "zero premium");
    }

    function test_RateClampedAtCap() public pure {
        require(FundingRateLib.computeRate(500) == 100, "clamp positive");
        require(FundingRateLib.computeRate(-500) == -100, "clamp negative");
        require(FundingRateLib.computeRate(25) == 25, "inside band passes through");
        require(FundingRateLib.computeRate(-25) == -25, "inside band passes through (neg)");
        require(FundingRateLib.computeRate(0) == 0, "zero rate");
    }

    function test_PaymentMath() public pure {
        // notional 5000 @ +100 bps => pay 50
        require(FundingRateLib.payment(5000e18, 100) == 50e18, "payment positive rate");
        // notional 5000 @ -100 bps => -50 (position receives)
        require(FundingRateLib.payment(5000e18, -100) == -50e18, "payment negative rate");
    }

    // -- health factor --------------------------------------------------------

    function test_HealthFactor() public pure {
        // equity 1000, notional 5000, MM 625 bps => MM requirement 312.5 => HF = 32000 bps (3.2x)
        require(HealthFactorLib.healthFactor(1000e18, 5000e18, 625) == 32000, "healthy factor");
        // equity 250 < MM 312.5 => HF = 8000 bps (< 10000 => liquidatable band)
        require(HealthFactorLib.healthFactor(250e18, 5000e18, 625) == 8000, "underwater factor");
        // no position => max health
        require(
            HealthFactorLib.healthFactor(0, 0, 625) == type(int256).max, "no position max health"
        );
    }

    function test_IsLiquidatable() public pure {
        require(!HealthFactorLib.isLiquidatable(1000e18, 5000e18, 625), "healthy not liquidatable");
        require(HealthFactorLib.isLiquidatable(250e18, 5000e18, 625), "underwater liquidatable");
        require(!HealthFactorLib.isLiquidatable(0, 0, 625), "no position not liquidatable");
        require(HealthFactorLib.isLiquidatable(-100e18, 5000e18, 625), "negative equity liquidatable");
    }
}
