// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IERC20StakingPool is IERC20 {
    function STAKING_TOKEN() external view returns (IERC20);
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
    function burn(uint256 amount) external;
}
