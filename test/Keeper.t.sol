// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../src/LiquidationKeeper.sol";
import "../src/mocks/MockPerpMarket.sol";

contract KeeperTest {
    MockPerpMarket internal market;
    LiquidationKeeper internal keeper;

    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant CAROL = address(0xCA401);

    uint256 internal constant INDEX = 2000e18; // $2,000

    function setUp() public {
        market = new MockPerpMarket();
        keeper = new LiquidationKeeper(address(market), INDEX, INDEX);
    }

    // -- funding push ---------------------------------------------------------

    function test_PushFunding_ClampsPositivePremium() public {
        keeper.setPrices(INDEX, 2100e18); // mark +5% over index => premium 500 bps
        require(keeper.currentFundingRate() == 100, "rate should clamp to cap");
        keeper.pushFunding(1 days);
        require(market.fundingCalls() == 1, "funding pushed once");
        require(market.lastRateBps() == 100, "market received clamped rate");
        require(market.lastPeriodSeconds() == 1 days, "period forwarded");
    }

    function test_PushFunding_NegativePremium() public {
        keeper.setPrices(INDEX, 1900e18); // mark -5% => premium -500 bps
        require(keeper.currentFundingRate() == -100, "negative rate clamped");
        keeper.pushFunding(8 hours);
        require(market.lastRateBps() == -100, "market received negative rate");
    }

    function test_PushFunding_ZeroPremium() public {
        require(keeper.currentFundingRate() == 0, "no premium => zero rate");
        keeper.pushFunding(1 days);
        require(market.lastRateBps() == 0, "zero rate pushed");
    }

    function test_OnlyOwnerSetsPrices() public {
        // calls from this test contract are the owner; simulate a stranger via low-level call
        // from a fresh contract address trick: use a helper that is not the owner.
        NonOwner caller = new NonOwner();
        try caller.trySetPrices(keeper, 1, 1) {
            require(false, "non-owner setPrices should revert");
        } catch {}
    }

    // -- liquidations ---------------------------------------------------------

    function test_CheckAndLiquidate_Batch() public {
        market.setLiquidatable(ALICE, true);
        market.setLiquidatable(BOB, false); // healthy — must be skipped, not revert
        market.setLiquidatable(CAROL, true);

        address[] memory watchlist = new address[](3);
        watchlist[0] = ALICE;
        watchlist[1] = BOB;
        watchlist[2] = CAROL;

        uint256 liquidated = keeper.checkAndLiquidate(watchlist);
        require(liquidated == 2, "two liquidations");
        require(market.liquidationCalls() == 2, "market saw two liquidations");
        require(!market.isLiquidatable(ALICE), "alice position closed");
        require(!market.isLiquidatable(BOB), "bob untouched");
    }

    function test_CheckAndLiquidate_EmptyWatchlist() public {
        address[] memory watchlist = new address[](0);
        uint256 liquidated = keeper.checkAndLiquidate(watchlist);
        require(liquidated == 0, "nothing to liquidate");
    }
}

/// @notice Helper that is not the keeper owner, used to test access control.
contract NonOwner {
    function trySetPrices(LiquidationKeeper keeper, uint256 idx, uint256 mark) external {
        keeper.setPrices(idx, mark);
    }
}
