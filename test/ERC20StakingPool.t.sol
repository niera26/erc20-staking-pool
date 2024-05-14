// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {ERC20StakingPoolERC20Rewards} from "../src/ERC20StakingPoolERC20Rewards.sol";
import {ERC20StakingPoolNativeRewards} from "../src/ERC20StakingPoolNativeRewards.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint256 _totalSupply) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply * (10 ** decimals()));
    }
}

contract ERC20StakingPoolTest is Test {
    IERC20Metadata public stakingToken;
    IERC20Metadata public rewardsToken;

    ERC20StakingPoolERC20Rewards public poolERC20;
    ERC20StakingPoolNativeRewards public poolNative;

    function setUp() public {
        stakingToken = new ERC20Mock("staking token", "STKN", 100_000_000);
        rewardsToken = new ERC20Mock("rewards token", "RTKN", 100_000_000);

        poolERC20 = new ERC20StakingPoolERC20Rewards("Staking pool token", "SPTKN", stakingToken, rewardsToken);
        poolNative = new ERC20StakingPoolNativeRewards("Staking pool token", "SPTKN", stakingToken);
    }

    function testTrue() public {
        assertTrue(true);
    }
}
