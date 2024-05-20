// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IERC20StakingPool {
    function staked(address addr) external view returns (uint256);
    function pendingSpoints(address addr) external view returns (uint256);
    function pendingRewards(address addr) external view returns (uint256);
    function stake(uint256 amount) external;
    function unstake(address to, uint256 amount) external;
    function claimAll() external;
    function claimSpoints() external;
    function claimRewards() external;
    function distribute() external;
    function emergencyWithdraw(address to, uint256 amount) external;
}
