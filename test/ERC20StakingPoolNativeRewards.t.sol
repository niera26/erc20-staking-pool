// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20StakingPoolNativeRewards} from "../src/ERC20StakingPoolNativeRewards.sol";
import {AbstractIntegrationTest} from "./AbstractIntegration.t.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint256 _totalSupply) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply * (10 ** decimals()));
    }
}

contract ERC20StakingPoolNativeRewardsTest is AbstractIntegrationTest {
    function setUp() public {
        stakingToken = new ERC20Mock("staking token", "STKN", 100_000_000);

        pool = new ERC20StakingPoolNativeRewards("Staking pool token", "SPTKN", stakingToken);
    }

    function dealRewardsToken(address addr, uint256 amount) internal override {
        deal(addr, amount);
    }

    function balanceOfRewardsToken(address addr) internal view override returns (uint256) {
        return addr.balance;
    }
}
