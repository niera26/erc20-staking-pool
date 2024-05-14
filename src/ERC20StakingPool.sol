// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20StakingPool is Ownable, ERC20, ERC20Burnable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable STAKING_TOKEN;
    IERC20Metadata public immutable REWARDS_TOKEN;

    uint256 public immutable STAKING_SCALE_FACTOR;
    uint256 public immutable REWARDS_SCALE_FACTOR;

    uint256 public constant PRECISION = 1e18;

    uint256 public totalStacked;

    mapping(address => Stakeholder) public stakeholders;

    uint256 public totalDistributed;
    uint256 public totalClaimed;

    uint256 public spointsPerBlock;
    uint256 public rewardsPerBlock;
    uint256 public lastDistributionBlock;

    uint256 public spointsPerToken;
    uint256 public rewardsPerToken;

    struct Stakeholder {
        uint256 amount;
        uint256 earnedSpoints;
        uint256 earnedRewards;
        uint256 spointsPerTokenLast;
        uint256 rewardsPerTokenLast;
    }

    event Stake(address indexed addr, uint256 amount);
    event Unstake(address indexed addr, uint256 amount);
    event Claim(address indexed addr, uint256 earnedSpoints, uint256 earnedRewards);

    constructor(string memory name, string memory symbol, IERC20Metadata stakingToken, IERC20Metadata rewardsToken)
        Ownable(msg.sender)
        ERC20(name, symbol)
    {
        STAKING_TOKEN = stakingToken;
        REWARDS_TOKEN = rewardsToken;

        uint8 stakingTokenDecimals = stakingToken.decimals();
        uint8 rewardsTokenDecimals = _rewardsTokenDecimals();

        require(stakingTokenDecimals <= 18, "!decimals");
        require(rewardsTokenDecimals <= 18, "!decimals");

        STAKING_SCALE_FACTOR = 10 ** (18 - stakingTokenDecimals);
        REWARDS_SCALE_FACTOR = 10 ** (18 - rewardsTokenDecimals);
    }

    function _isNativeRewards() private view returns (bool) {
        return address(0) == address(REWARDS_TOKEN);
    }

    function _rewardsTokenDecimals() private view returns (uint8) {
        return _isNativeRewards() ? 18 : REWARDS_TOKEN.decimals();
    }

    function _transferRewardsToken(address to, uint256 amount) private {
        if (!_isNativeRewards()) {
            REWARDS_TOKEN.safeTransfer(to, amount);
        }

        (bool sent,) = payable(to).call{value: amount}("");

        require(sent, "!transfer");
    }

    function rewardsTokenBalance() public view returns (uint256) {
        return _isNativeRewards() ? address(this).balance : REWARDS_TOKEN.balanceOf(address(this));
    }

    function rewardsTokenAvailable() public view returns (uint256) {
        uint256 balance = rewardsTokenBalance();
        uint256 amountToClaim = totalDistributed - totalClaimed;

        return balance - amountToClaim;
    }

    function rewardsTokenEmitted() public view returns (uint256) {
        uint256 availableAmount = rewardsTokenAvailable();
        uint256 emittedAmount = (block.number - lastDistributionBlock) * rewardsPerBlock;

        return emittedAmount < availableAmount ? emittedAmount : availableAmount;
    }

    function spointsTokenEmitted() public view returns (uint256) {
        return (block.number - lastDistributionBlock) * spointsPerBlock;
    }

    function staked(address addr) external view returns (uint256) {
        return stakeholders[addr].amount;
    }

    function pendingSpoints(address addr) external view returns (uint256) {
        return _pendingSpoints(stakeholders[addr]);
    }

    function pendingRewards(address addr) external view returns (uint256) {
        return _pendingRewards(stakeholders[addr]);
    }

    function stake(uint256 amount) external {
        Stakeholder storage stakeholder = stakeholders[msg.sender];

        distribute();
        _earnSpoints(stakeholder);
        _earnRewards(stakeholder);

        totalStacked += amount;
        stakeholder.amount += amount;

        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        Stakeholder storage stakeholder = stakeholders[msg.sender];

        distribute();
        _earnSpoints(stakeholder);
        _earnRewards(stakeholder);

        totalStacked -= amount;
        stakeholder.amount -= amount;

        STAKING_TOKEN.transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    function claimAll(address addr) external {
        Stakeholder storage stakeholder = stakeholders[addr];

        distribute();
        _earnSpoints(stakeholder);
        _earnRewards(stakeholder);

        uint256 earnedSpoints = stakeholder.earnedSpoints;
        uint256 earnedRewards = stakeholder.earnedRewards;

        stakeholder.earnedSpoints = 0;
        stakeholder.earnedRewards = 0;

        _mint(addr, earnedSpoints);
        _transferRewardsToken(addr, earnedRewards);

        emit Claim(msg.sender, earnedSpoints, earnedRewards);
    }

    function claimSpoints(address addr) external {
        Stakeholder storage stakeholder = stakeholders[addr];

        distribute();
        _earnSpoints(stakeholder);

        uint256 earnedSpoints = stakeholder.earnedSpoints;

        stakeholder.earnedSpoints = 0;

        _mint(addr, earnedSpoints);

        emit Claim(msg.sender, earnedSpoints, 0);
    }

    function claimRewards(address addr) external {
        Stakeholder storage stakeholder = stakeholders[addr];

        distribute();
        _earnRewards(stakeholder);

        uint256 earnedRewards = stakeholder.earnedRewards;

        stakeholder.earnedRewards = 0;

        _transferRewardsToken(addr, earnedRewards);

        emit Claim(msg.sender, 0, earnedRewards);
    }

    function distribute() public {
        if (totalStacked == 0) return;

        uint256 emittedSpointsAmount = spointsTokenEmitted();
        uint256 emittedRewardsAmount = rewardsTokenEmitted();

        lastDistributionBlock = block.number;

        spointsPerToken += (emittedSpointsAmount * PRECISION) / (totalStacked * STAKING_SCALE_FACTOR);

        rewardsPerToken +=
            (emittedRewardsAmount * REWARDS_SCALE_FACTOR * PRECISION) / (totalStacked * STAKING_SCALE_FACTOR);
    }

    function _pendingSpoints(Stakeholder memory stakeholder) private view returns (uint256) {
        uint256 RDiff = spointsPerToken - stakeholder.spointsPerTokenLast;

        return stakeholder.earnedSpoints + (RDiff * stakeholder.amount * STAKING_SCALE_FACTOR) / PRECISION;
    }

    function _earnSpoints(Stakeholder storage stakeholder) private {
        stakeholder.earnedSpoints = _pendingSpoints(stakeholder);
        stakeholder.spointsPerTokenLast = spointsPerToken;
    }

    function _pendingRewards(Stakeholder memory stakeholder) private view returns (uint256) {
        uint256 RDiff = rewardsPerToken - stakeholder.rewardsPerTokenLast;

        return stakeholder.earnedRewards
            + (RDiff * stakeholder.amount * STAKING_SCALE_FACTOR) / (REWARDS_SCALE_FACTOR * PRECISION);
    }

    function _earnRewards(Stakeholder storage stakeholder) private {
        stakeholder.earnedRewards = _pendingRewards(stakeholder);
        stakeholder.rewardsPerTokenLast = rewardsPerToken;
    }
}
