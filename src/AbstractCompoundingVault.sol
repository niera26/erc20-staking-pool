// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20StakingPool} from "./IERC20StakingPool.sol";

abstract contract AbstractCompoundingVault is ERC4626 {
    IERC20StakingPool public immutable pool;

    event Compound(address indexed addr, uint256 amount);

    constructor(string memory name, string memory symbol, IERC20StakingPool _pool)
        ERC20(name, symbol)
        ERC4626(pool.STAKING_TOKEN())
    {
        pool = _pool;
    }

    function _swapRewardsToAssets() internal virtual {}

    function totalAssets() public view override returns (uint256) {
        return pool.staked(address(this));
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        SafeERC20.safeTransferFrom(pool.STAKING_TOKEN(), caller, address(this), assets);
        _mint(receiver, shares);

        pool.stake(assets);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        pool.unstake(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function compound() external {
        pool.claimRewards();

        _swapRewardsToAssets();

        uint256 assets = pool.STAKING_TOKEN().balanceOf(address(this));

        pool.stake(assets);

        emit Compound(msg.sender, assets);
    }
}
