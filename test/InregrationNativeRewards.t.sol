// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {AbstractERC20StakingPool} from "../src/AbstractERC20StakingPool.sol";
import {ERC20StakingPoolNativeRewards} from "../src/ERC20StakingPoolNativeRewards.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint256 _totalSupply) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply * (10 ** decimals()));
    }
}

contract InregrationNativeRewardsTest is Test {
    IERC20Metadata public stakingToken;

    AbstractERC20StakingPool public pool;

    event Stake(address indexed addr, uint256 amount);
    event Unstake(address indexed addr, address indexed to, uint256 amount);
    event Claim(address indexed addr, address indexed to, uint256 spointsAmount, uint256 rewardsAmount);

    function setUp() public {
        stakingToken = new ERC20Mock("staking token", "STKN", 100_000_000);

        pool = new ERC20StakingPoolNativeRewards("Staking pool token", "SPTKN", stakingToken);
    }

    function approve(address addr, uint256 amount) internal {
        vm.prank(addr);

        stakingToken.approve(address(pool), amount);
    }

    function dealStakingToken(address addr, uint256 amount) internal {
        deal(address(stakingToken), addr, amount);
    }

    function dealRewardsToken(address addr, uint256 amount) internal {
        deal(addr, amount);
    }

    function balanceOfStakingToken(address addr) internal view returns (uint256) {
        return stakingToken.balanceOf(addr);
    }

    function balanceOfSpointsToken(address addr) internal view returns (uint256) {
        return pool.balanceOf(addr);
    }

    function balanceOfRewardsToken(address addr) internal view returns (uint256) {
        return addr.balance;
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

    function testIntegration(uint256 startBlock) public {
        address user1 = address(1);
        address user2 = address(2);
        address user3 = address(3);

        startBlock = bound(startBlock, 10_000, 20_000);

        dealStakingToken(address(pool), 100_000);
        assertEq(balanceOfStakingToken(address(pool)), 100_000);

        dealRewardsToken(address(pool), 100_000_000);
        assertEq(balanceOfRewardsToken(address(pool)), 100_000_000);

        assertEq(pool.spointsPerBlock(), 0);
        pool.setSpointsPerBlock(1_000_000);
        assertEq(pool.spointsPerBlock(), 1_000_000);

        assertEq(pool.rewardsPerBlock(), 0);
        pool.setRewardsPerBlock(10_000_000);
        assertEq(pool.rewardsPerBlock(), 10_000_000);

        // first user stake once.
        vm.roll(startBlock);

        dealStakingToken(user1, 2_000);

        assertEq(balanceOfStakingToken(user1), 2_000);

        approve(user1, 2_000);
        expectStakeEvent(user1, 2_000);
        stake(user1, 2_000);

        assertEq(stacked(user1), 2_000);
        assertEq(stacked(user2), 0);
        assertApproxEqAbs(pendingSpoints(user1), 0, 10);
        assertApproxEqAbs(pendingSpoints(user2), 0, 10);
        assertApproxEqAbs(pendingRewards(user1), 0, 10);
        assertApproxEqAbs(pendingRewards(user2), 0, 10);
        assertEq(balanceOfStakingToken(user1), 0);
        assertEq(balanceOfStakingToken(user2), 0);
        assertEq(balanceOfStakingToken(address(pool)), 102_000);
        assertEq(pool.totalStaked(), 2_000);
        assertEq(pool.totalRewardsDistributed(), 0);

        // second user stake once.
        vm.roll(block.number + 1);

        dealStakingToken(user2, 6_000);

        assertEq(balanceOfStakingToken(user2), 6_000);

        approve(user2, 6_000);
        expectStakeEvent(user2, 6_000);
        stake(user2, 6_000);

        assertEq(stacked(user1), 2_000);
        assertEq(stacked(user2), 6_000);
        assertApproxEqAbs(pendingSpoints(user1), 1_000_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 0, 10);
        assertApproxEqAbs(pendingRewards(user1), 10_000_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 0, 10);
        assertEq(balanceOfStakingToken(user1), 0);
        assertEq(balanceOfStakingToken(user2), 0);
        assertEq(balanceOfStakingToken(address(pool)), 108_000);
        assertEq(pool.totalStaked(), 8_000);
        assertEq(pool.totalRewardsDistributed(), 10_000_000);

        // first user stake a second time.
        vm.roll(block.number + 1);

        dealStakingToken(user1, 16_000);

        assertEq(balanceOfStakingToken(user1), 16_000);

        approve(user1, 16_000);
        expectStakeEvent(user1, 16_000);
        stake(user1, 16_000);

        assertEq(stacked(user1), 18_000);
        assertEq(stacked(user2), 6_000);
        assertApproxEqAbs(pendingSpoints(user1), 1_250_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 750_000, 10);
        assertApproxEqAbs(pendingRewards(user1), 12_500_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 7_500_000, 10);
        assertEq(balanceOfStakingToken(user1), 0);
        assertEq(balanceOfStakingToken(user2), 0);
        assertEq(balanceOfStakingToken(address(pool)), 124_000);
        assertEq(pool.totalStaked(), 24_000);
        assertEq(pool.totalRewardsDistributed(), 20_000_000);

        // second user stake a second time.
        vm.roll(block.number + 1);

        dealStakingToken(user2, 12_000);

        assertEq(balanceOfStakingToken(user2), 12_000);

        approve(user2, 12_000);
        expectStakeEvent(user2, 12_000);
        stake(user2, 12_000);

        assertEq(stacked(user1), 18_000);
        assertEq(stacked(user2), 18_000);
        assertApproxEqAbs(pendingSpoints(user1), 2_000_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 1_000_000, 10);
        assertApproxEqAbs(pendingRewards(user1), 20_000_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 10_000_000, 10);
        assertEq(balanceOfStakingToken(user1), 0);
        assertEq(balanceOfStakingToken(user2), 0);
        assertEq(balanceOfStakingToken(address(pool)), 136_000);
        assertEq(pool.totalStaked(), 36_000);
        assertEq(pool.totalRewardsDistributed(), 30_000_000);

        // first user unstake a first time.
        vm.roll(block.number + 1);

        expectUnstakeEvent(user1, user1, 6_000);
        unstake(user1, user1, 6_000);

        assertEq(stacked(user1), 12_000);
        assertEq(stacked(user2), 18_000);
        assertApproxEqAbs(pendingSpoints(user1), 2_500_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 1_500_000, 10);
        assertApproxEqAbs(pendingRewards(user1), 25_000_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 15_000_000, 10);
        assertEq(balanceOfStakingToken(user1), 6_000);
        assertEq(balanceOfStakingToken(user2), 0);
        assertEq(balanceOfStakingToken(address(pool)), 130_000);
        assertEq(pool.totalStaked(), 30_000);
        assertEq(pool.totalRewardsDistributed(), 40_000_000);

        // second user unstake a first time.
        vm.roll(block.number + 1);

        expectUnstakeEvent(user2, user2, 14_000);
        unstake(user2, user2, 14_000);

        assertEq(stacked(user1), 12_000);
        assertEq(stacked(user2), 4_000);
        assertApproxEqAbs(pendingSpoints(user1), 2_900_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 2_100_000, 10);
        assertApproxEqAbs(pendingRewards(user1), 29_000_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 21_000_000, 10);
        assertEq(balanceOfStakingToken(user1), 6_000);
        assertEq(balanceOfStakingToken(user2), 14_000);
        assertEq(balanceOfStakingToken(address(pool)), 116_000);
        assertEq(pool.totalStaked(), 16_000);
        assertEq(pool.totalRewardsDistributed(), 50_000_000);

        // first user unstake a second time.
        vm.roll(block.number + 1);

        expectUnstakeEvent(user1, user1, 12_000);
        unstake(user1, user1, 12_000);

        assertEq(stacked(user1), 0);
        assertEq(stacked(user2), 4_000);
        assertApproxEqAbs(pendingSpoints(user1), 3_650_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 2_350_000, 10);
        assertApproxEqAbs(pendingRewards(user1), 36_500_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 23_500_000, 10);
        assertEq(balanceOfStakingToken(user1), 18_000);
        assertEq(balanceOfStakingToken(user2), 14_000);
        assertEq(balanceOfStakingToken(address(pool)), 104_000);
        assertEq(pool.totalStaked(), 4_000);
        assertEq(pool.totalRewardsDistributed(), 60_000_000);

        // second user unstake a second time.
        vm.roll(block.number + 1);

        expectUnstakeEvent(user2, user2, 4_000);
        unstake(user2, user2, 4_000);

        assertEq(stacked(user1), 0);
        assertEq(stacked(user2), 0);
        assertApproxEqAbs(pendingSpoints(user1), 3_650_000, 10);
        assertApproxEqAbs(pendingSpoints(user2), 3_350_000, 10);
        assertApproxEqAbs(pendingRewards(user1), 36_500_000, 10);
        assertApproxEqAbs(pendingRewards(user2), 33_500_000, 10);
        assertEq(balanceOfStakingToken(user1), 18_000);
        assertEq(balanceOfStakingToken(user2), 18_000);
        assertEq(balanceOfStakingToken(address(pool)), 100_000);
        assertEq(pool.totalStaked(), 0);
        assertEq(pool.totalRewardsDistributed(), 70_000_000);

        // third user stake, it restarts.
        vm.roll(block.number + 1);

        dealStakingToken(user3, 1_000);

        assertEq(balanceOfStakingToken(user3), 1_000);

        approve(user3, 1_000);
        expectStakeEvent(user3, 1_000);
        stake(user3, 1_000);

        assertEq(stacked(user3), 1_000);
        assertEq(pendingSpoints(user3), 0);
        assertEq(pendingRewards(user3), 0);
        assertEq(balanceOfStakingToken(user3), 0);
        assertEq(balanceOfStakingToken(address(pool)), 101_000);
        assertEq(pool.totalStaked(), 1_000);
        assertEq(pool.totalRewardsDistributed(), 70_000_000);

        // third user unstake.
        vm.roll(block.number + 1);

        expectUnstakeEvent(user3, user3, 1_000);
        unstake(user3, user3, 1_000);

        assertEq(stacked(user3), 0);
        assertEq(pendingSpoints(user3), 1_000_000);
        assertEq(pendingRewards(user3), 10_000_000);
        assertEq(balanceOfStakingToken(user3), 1_000);
        assertEq(balanceOfStakingToken(address(pool)), 100_000);
        assertEq(pool.totalStaked(), 0);
        assertEq(pool.totalRewardsDistributed(), 80_000_000);

        // test claims.
        uint256 snapshot;
        uint256 originalPendingSpoints;
        uint256 originalPendingRewards;
        uint256 originalRewardsBalance;
        uint256 totalRewardsClaimed;

        snapshot = vm.snapshot();

        // test all users can claim both rewards and spoints.
        originalPendingSpoints = pendingSpoints(user1);
        originalPendingRewards = pendingRewards(user1);
        originalRewardsBalance = balanceOfRewardsToken(user1);
        totalRewardsClaimed = originalPendingRewards;

        expectClaimEvent(user1, user1, originalPendingSpoints, originalPendingRewards);
        claimAll(user1, user1);
        assertEq(pendingSpoints(user1), 0);
        assertEq(pendingRewards(user1), 0);
        assertEq(balanceOfSpointsToken(user1), originalPendingSpoints);
        assertEq(balanceOfRewardsToken(user1), originalRewardsBalance + originalPendingRewards);
        assertEq(pool.totalRewardsClaimed(), totalRewardsClaimed);

        originalPendingSpoints = pendingSpoints(user2);
        originalPendingRewards = pendingRewards(user2);
        originalRewardsBalance = balanceOfRewardsToken(user2);
        totalRewardsClaimed += originalPendingRewards;

        expectClaimEvent(user2, user2, originalPendingSpoints, originalPendingRewards);
        claimAll(user2, user2);
        assertEq(pendingSpoints(user2), 0);
        assertEq(pendingRewards(user2), 0);
        assertEq(balanceOfSpointsToken(user2), originalPendingSpoints);
        assertEq(balanceOfRewardsToken(user2), originalRewardsBalance + originalPendingRewards);
        assertEq(pool.totalRewardsClaimed(), totalRewardsClaimed);

        originalPendingSpoints = pendingSpoints(user3);
        originalPendingRewards = pendingRewards(user3);
        originalRewardsBalance = balanceOfRewardsToken(user3);
        totalRewardsClaimed += originalPendingRewards;

        expectClaimEvent(user3, user3, originalPendingSpoints, originalPendingRewards);
        claimAll(user3, user3);
        assertEq(pendingSpoints(user3), 0);
        assertEq(pendingRewards(user3), 0);
        assertEq(balanceOfSpointsToken(user3), originalPendingSpoints);
        assertEq(balanceOfRewardsToken(user3), originalRewardsBalance + originalPendingRewards);
        assertEq(pool.totalRewardsClaimed(), totalRewardsClaimed);

        vm.revertTo(snapshot);

        // test all users can claim spoints only.
        originalPendingSpoints = pendingSpoints(user1);
        originalPendingRewards = pendingRewards(user1);
        originalRewardsBalance = balanceOfRewardsToken(user1);
        totalRewardsClaimed = originalPendingRewards;

        expectClaimEvent(user1, user1, originalPendingSpoints, 0);
        claimSpoints(user1, user1);
        assertEq(pendingSpoints(user1), 0);
        assertEq(pendingRewards(user1), originalPendingRewards);
        assertEq(balanceOfSpointsToken(user1), originalPendingSpoints);
        assertEq(balanceOfRewardsToken(user1), originalRewardsBalance);
        assertEq(pool.totalRewardsClaimed(), 0);

        originalPendingSpoints = pendingSpoints(user2);
        originalPendingRewards = pendingRewards(user2);
        originalRewardsBalance = balanceOfRewardsToken(user2);
        totalRewardsClaimed += originalPendingRewards;

        expectClaimEvent(user2, user2, originalPendingSpoints, 0);
        claimSpoints(user2, user2);
        assertEq(pendingSpoints(user2), 0);
        assertEq(pendingRewards(user2), originalPendingRewards);
        assertEq(balanceOfSpointsToken(user2), originalPendingSpoints);
        assertEq(balanceOfRewardsToken(user2), originalRewardsBalance);
        assertEq(pool.totalRewardsClaimed(), 0);

        originalPendingSpoints = pendingSpoints(user3);
        originalPendingRewards = pendingRewards(user3);
        originalRewardsBalance = balanceOfRewardsToken(user3);
        totalRewardsClaimed += originalPendingRewards;

        expectClaimEvent(user3, user3, originalPendingSpoints, 0);
        claimSpoints(user3, user3);
        assertEq(pendingSpoints(user3), 0);
        assertEq(pendingRewards(user3), originalPendingRewards);
        assertEq(balanceOfSpointsToken(user3), originalPendingSpoints);
        assertEq(balanceOfRewardsToken(user3), originalRewardsBalance);
        assertEq(pool.totalRewardsClaimed(), 0);

        vm.revertTo(snapshot);

        // test all users can claim rewards only.
        originalPendingSpoints = pendingSpoints(user1);
        originalPendingRewards = pendingRewards(user1);
        originalRewardsBalance = balanceOfRewardsToken(user1);
        totalRewardsClaimed = originalPendingRewards;

        expectClaimEvent(user1, user1, 0, originalPendingRewards);
        claimRewards(user1, user1);
        assertEq(pendingSpoints(user1), originalPendingSpoints);
        assertEq(pendingRewards(user1), 0);
        assertEq(balanceOfSpointsToken(user1), 0);
        assertEq(balanceOfRewardsToken(user1), originalRewardsBalance + originalPendingRewards);
        assertEq(pool.totalRewardsClaimed(), totalRewardsClaimed);

        originalPendingSpoints = pendingSpoints(user2);
        originalPendingRewards = pendingRewards(user2);
        originalRewardsBalance = balanceOfRewardsToken(user2);
        totalRewardsClaimed += originalPendingRewards;

        expectClaimEvent(user2, user2, 0, originalPendingRewards);
        claimRewards(user2, user2);
        assertEq(pendingSpoints(user2), originalPendingSpoints);
        assertEq(pendingRewards(user2), 0);
        assertEq(balanceOfSpointsToken(user2), 0);
        assertEq(balanceOfRewardsToken(user2), originalRewardsBalance + originalPendingRewards);
        assertEq(pool.totalRewardsClaimed(), totalRewardsClaimed);

        originalPendingSpoints = pendingSpoints(user3);
        originalPendingRewards = pendingRewards(user3);
        originalRewardsBalance = balanceOfRewardsToken(user3);
        totalRewardsClaimed += originalPendingRewards;

        expectClaimEvent(user3, user3, 0, originalPendingRewards);
        claimRewards(user3, user3);
        assertEq(pendingSpoints(user3), originalPendingSpoints);
        assertEq(pendingRewards(user3), 0);
        assertEq(balanceOfSpointsToken(user3), 0);
        assertEq(balanceOfRewardsToken(user3), originalRewardsBalance + originalPendingRewards);
        assertEq(pool.totalRewardsClaimed(), totalRewardsClaimed);
    }
}
