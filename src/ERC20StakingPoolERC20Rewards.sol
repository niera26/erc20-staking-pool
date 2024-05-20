// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {AbstractERC20StakingPool} from "./AbstractERC20StakingPool.sol";

contract ERC20StakingPoolERC20Rewards is AbstractERC20StakingPool {
    IERC20Metadata public immutable REWARDS_TOKEN;

    constructor(string memory name, string memory symbol, IERC20Metadata stakingToken, IERC20Metadata rewardsToken)
        AbstractERC20StakingPool(name, symbol, stakingToken)
    {
        REWARDS_TOKEN = rewardsToken;

        uint8 rewardsTokenDecimals = rewardsToken.decimals();

        require(rewardsTokenDecimals <= 18, "!decimals");

        REWARDS_SCALE_FACTOR = 10 ** (18 - rewardsTokenDecimals);
    }

    function rewardsBalance() public view override returns (uint256) {
        return REWARDS_TOKEN.balanceOf(address(this));
    }

    function _transferRewardsToken(address to, uint256 amount) internal override {
        SafeERC20.safeTransfer(REWARDS_TOKEN, to, amount);
    }
}
