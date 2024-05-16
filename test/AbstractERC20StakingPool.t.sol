// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {AbstractERC20StakingPool} from "../src/AbstractERC20StakingPool.sol";
import {ERC20StakingPoolNativeRewards} from "../src/ERC20StakingPoolNativeRewards.sol";

abstract contract AbstractERC20StakingPoolTest is Test {
    IERC20Metadata internal stakingToken;

    AbstractERC20StakingPool internal pool;

    event Stake(address indexed addr, uint256 amount);
    event Unstake(address indexed addr, address indexed to, uint256 amount);
    event Claim(address indexed addr, address indexed to, uint256 spointsAmount, uint256 rewardsAmount);

    function dealRewardsToken(address addr, uint256 amount) internal virtual;
    function balanceOfRewardsToken(address addr) internal view virtual returns (uint256);

    function approve(address addr, uint256 amount) internal {
        vm.prank(addr);

        stakingToken.approve(address(pool), amount);
    }

    function dealStakingToken(address addr, uint256 amount) internal {
        deal(address(stakingToken), addr, amount);
    }

    function balanceOfStakingToken(address addr) internal view returns (uint256) {
        return stakingToken.balanceOf(addr);
    }

    function balanceOfSpointsToken(address addr) internal view returns (uint256) {
        return pool.balanceOf(addr);
    }

    function stacked(address addr) internal view returns (uint256) {
        return pool.staked(addr);
    }

    function pendingSpoints(address addr) internal view returns (uint256) {
        return pool.pendingSpoints(addr);
    }

    function pendingRewards(address addr) internal view returns (uint256) {
        return pool.pendingRewards(addr);
    }

    function stake(address addr, uint256 amount) internal {
        vm.prank(addr);

        pool.stake(amount);
    }

    function unstake(address addr, address to, uint256 amount) internal {
        vm.prank(addr);

        pool.unstake(to, amount);
    }

    function claimAll(address addr, address to) internal {
        vm.prank(addr);

        pool.claimAll(to);
    }

    function claimSpoints(address addr, address to) internal {
        vm.prank(addr);

        pool.claimSpoints(to);
    }

    function claimRewards(address addr, address to) internal {
        vm.prank(addr);

        pool.claimRewards(to);
    }

    function expectStakeEvent(address addr, uint256 amount) internal {
        vm.expectEmit(true, true, true, true, address(pool));
        emit Stake(addr, amount);
    }

    function expectUnstakeEvent(address addr, address to, uint256 amount) internal {
        vm.expectEmit(true, true, true, true, address(pool));
        emit Unstake(addr, to, amount);
    }

    function expectClaimEvent(address addr, address to, uint256 spointsAmount, uint256 rewardsAmount) internal {
        vm.expectEmit(true, true, true, true, address(pool));
        emit Claim(addr, to, spointsAmount, rewardsAmount);
    }
}
