// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {ERC20StakingPoolERC20Rewards} from "../src/ERC20StakingPoolERC20Rewards.sol";
import {AbstractIntegrationTest} from "./AbstractIntegration.t.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint256 _totalSupply) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply * (10 ** decimals()));
    }
}

contract ERC20StakingPoolERC20RewardsTest is AbstractIntegrationTest {
    IERC20Metadata private rewardsToken;

    function setUp() public {
        stakingToken = new ERC20Mock("staking token", "STKN", 100_000_000);
        rewardsToken = new ERC20Mock("rewards token", "RTKN", 100_000_000);

        pool = new ERC20StakingPoolERC20Rewards("Staking pool token", "SPTKN", stakingToken, rewardsToken);
    }

    function dealRewardsToken(address addr, uint256 amount) internal override {
        deal(address(rewardsToken), addr, amount);
    }

    function balanceOfRewardsToken(address addr) internal view override returns (uint256) {
        return rewardsToken.balanceOf(addr);
    }
}
