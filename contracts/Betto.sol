// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Betto Token (BET)
 * @notice implements an ERC20 staking token with incentive distribution.
 */
contract Betto is ERC20, Ownable {

    /**
     * @notice list of stakeholders
     */
    address[] internal stakeholders;
    /**
     * @notice The stakes for each stakeholder
     */
    mapping(address => uint256) internal stakes;
    /**
     * @notice The accumulated rewards for each stakeholder
     */
     mapping(address => uint256) internal rewards;
    

    /**
     * @notice The constructor to initialize setup values
     * @param _supply The amount total tokens on deployment
     */
    constructor(uint256 _supply) ERC20("Betto", "BET") {
        _mint(msg.sender, _supply);
    }

    /**
     * @notice Checks if an address belongs to stakeholder
     * @param _address The address to check
     * @return bool true if the address belongs to a stakeholder; otherwise, false
     * @return uint256 the index of the address in the stakeholders' array; 
     * zero if the address is not a stakeholder
     */
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for(uint256 s = 0; s < stakeholders.length; s++) {
            if(_address == stakeholders[s]) return (true, s);
        }

        return (false, 0);
    }

    /**
     * @notice Adds a stakeholder
     * @param _stakeholder The stakeholder's address to be added
     */
    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice Removes a stakeholder
     * @param _stakeholder The stakeholder to be removed
     */
    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }
    /**
     * @notice Retrieves the stake for a given stakeholder
     * @param _stakeholder The stakeholder to retrieve the stake for
     * @return uint256 The amount of wei staked
     */
    function stakeOf(address _stakeholder) public view returns(uint256) {
        return stakes[_stakeholder];
    }

    /**
     * @notice Gets the sum of all stakes
     * @return uint256 The sum of all stakes
     */
    function totalStakes() public view returns(uint256) {
        uint256 _totalStakes = 0;

        for(uint256 s = 0; s < stakeholders.length; s++){
            _totalStakes += stakes[stakeholders[s]];
        }

        return _totalStakes;
    }

    /**
     * @notice A stakeholder creates a stake
     * @dev we add stakeholder to be used in the reward system
     * we would `_burn` tokens as they are staked to stop users from transferring them
     * until the stake is removed
     * `_burn` will revert if the user attempts to stake more tokens than the user owns
     * @param _stake The amount of the stake to be created.
     */
    function createStake(uint256 _stake) public{
        address _owner = msg.sender;
        _burn(_owner, _stake);
        if(stakes[_owner] == 0) addStakeholder(_owner);
        stakes[_owner] += _stake;
    }

    /**
     * @notice A stakeholder removes a stake
     * @dev we remove stakeholder to prevent participation in reward system if the stake is zero
     * The update stake mapping `stakes[_owner] -= _stake` would revert 
     * if there is an attempt to remove more tokens than  were staked (SafeMath)
     * @param _stake The amount of stake to be removed
     */
     function removeStake(uint256 _stake) public {
         address _owner = msg.sender;
         stakes[_owner] -= _stake;
         if(stakes[_owner] == 0) removeStakeholder(_owner);
         _mint(_owner, _stake);
     }
     /**
      * @notice Gets the rewards of a given stakeholder
      * @param _stakeholder The stakeholder to check rewards for.
      */
     function rewardOf(address _stakeholder) public view returns(uint256) {
         return rewards[_stakeholder];
     }

     /**
      * @notice Gets the rewards of all stakeholders
      * @return uint256 the sum of all rewards of all stakeholders
      */
     function totalRewards() public view returns (uint256) {

         uint256 _totalRewards = 0;

         for(uint256 s = 0; s < stakeholders.length; s++) {
             _totalRewards += rewards[stakeholders[s]];
         }

         return _totalRewards;
     }

     /**
      * @notice Calculates the reward for a given stakeholder.
      * @param _stakeholder The stakeholder to calculate reward for
      */
     function calculateRewards(address _stakeholder) public view returns(uint256) {
         return stakes[_stakeholder] / 100;
     }

     function distributeRewards() public onlyOwner {
         for(uint256 s = 0; s < stakeholders.length; s++) {
             address stakeholder = stakeholders[s];
             uint256 reward = calculateRewards(stakeholder);
             rewards[stakeholder] += reward;
         }
     }

     /**
      * @notice Allows a stakeholder to withdraw rewards
      */
      function withdrawReward() public {
          address owner = msg.sender;
          uint256 reward = rewards[owner];
          rewards[owner] = 0;
          _mint(owner, reward);
      }
}