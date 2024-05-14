// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20StakingContract is Ownable, ERC20, ERC20Burnable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable STAKING_TOKEN;

    uint256 public immutable SCALE_FACTOR;

    uint256 public constant PRECISION = 1e18;

    constructor(string memory name, string memory symbol, IERC20Metadata stakingToken)
        Ownable(msg.sender)
        ERC20(name, symbol)
    {
        uint8 decimals = stakingToken.decimals();

        require(decimals <= 18, "!decimals");

        STAKING_TOKEN = stakingToken;
        SCALE_FACTOR = 10 ** (18 - decimals);
    }
}
