// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AbstractERC20StakingPool} from "./AbstractERC20StakingPool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

contract ERC20StakingPoolNativeRewards is AbstractERC20StakingPool {
    constructor(string memory name, string memory symbol, IERC20Metadata stakingToken)
        AbstractERC20StakingPool(name, symbol, stakingToken)
    {
        REWARDS_SCALE_FACTOR = 1; // native token has 18 decimals.
    }

    function rewardsBalance() public view override returns (uint256) {
        return address(this).balance;
    }

    function _transferRewardsToken(address to, uint256 amount) internal override {
        (bool sent,) = payable(to).call{value: amount}("");

        require(sent, "!transfer");
    }

    fallback() external payable {}

    receive() external payable {}
}
