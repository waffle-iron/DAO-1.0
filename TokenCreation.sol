/*
This file is part of the DaoCasino and was cloned from original DAO.

The DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http://www.gnu.org/licenses/>.
*/


/*
 * Token Creation contract, used by the DAO to create its tokens and initialize
 * its ether. Feel free to modify the divisor method to implement different
 * Token Creation parameters
*/

import "./Token.sol";
import "./ManagedAccount.sol";

contract TokenCreationInterface {
    // End of token creation, in Unix time
    uint public closingTime;
    // Minimum fueling goal of the token creation, denominated in tokens to
    // be created (not including DaoCasino reward)
    uint public minTokensToCreate;
    // True if the DAO reached its minimum fueling goal, false otherwise
    bool public isFueled;
    // True if DaoCasino team got extra rewards
    bool public isTeamRewarded;
    // For DAO splits - if privateCreation is 0, then it is a public token
    // creation, otherwise only the address stored in privateCreation is
    // allowed to create tokens
    address public privateCreation;
    // This is our DaoCasino team address.
    // After DAO is fueled -> we will get 15% token here
    // (10% as reward + 5% for development)
    address public teamRewardAccount;
    // hold extra ether which has been sent after the DAO token
    // creation rate has increased
    ManagedAccount public extraBalance;
    // tracks the amount of wei given from each contributor (used for refund)
    mapping (address => uint256) weiGiven;

    /// @dev Constructor setting the minimum fueling goal and the
    /// end of the Token Creation
    /// @param _minTokensToCreate Minimum fueling goal in number of
    ///        Tokens to be created
    /// @param _closingTime Date (in Unix time) of the end of the Token Creation
    /// @param _privateCreation Zero means that the creation is public.  A
    /// non-zero address represents the only address that can create Tokens
    /// (the address can also create Tokens on behalf of other accounts)
    // This is the constructor: it can not be overloaded so it is commented out
    //  function TokenCreation(
        //  uint _minTokensTocreate,
        //  uint _closingTime,
        //  address _privateCreation
    //  );

    /// @notice Create Token with `_tokenHolder` as the initial owner of the Token
    /// @param _tokenHolder The address of the Tokens's recipient
    /// @return Whether the token creation was successful
    function createTokenProxy(address _tokenHolder) returns (bool success);

    /// @notice After ICO is finished - call this method in order to receive 
    /// DaoCasino extra team reward
    function rewardTeam() returns (bool success);

    /// @notice Refund `msg.sender` in the case the Token Creation did
    /// not reach its minimum fueling goal
    function refund();

    /// @return The divisor used to calculate the token creation rate during
    /// the creation phase
    function divisor() constant returns (uint divisor);
// Events:
    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
}


contract TokenCreation is TokenCreationInterface, Token {
    function TokenCreation(
        uint _minTokensToCreate,
        uint _closingTime,
        address _privateCreation,
        address _teamRewardAccount) {

        closingTime = _closingTime;
        minTokensToCreate = _minTokensToCreate;
        privateCreation = _privateCreation;
        teamRewardAccount = _teamRewardAccount;
        extraBalance = new ManagedAccount(address(this), true);
    }

    function createTokenProxy(address _tokenHolder) returns (bool success) {
        if (now < closingTime && msg.value > 0
            && (privateCreation == 0 || privateCreation == msg.sender)) {

            uint token = (msg.value * 20) / divisor();

            // There is a simple attack that consists of buying tokens at 
            // price 1 and then splittin immediately after the creation process 
            // ends. In this case, the attacker would get more than 1Ξ for each Ξ 
            // invested if there are people buying Ð at more than 1Ξ/100Ð.
            // 
            // To solve that, developers created the extraBalance account. 
            // This account stores the extra money that the DAO gets in the final 
            // phases above 1Ξ/100Ð.
            //
            // For example, if you buy 100Ð for 1.5Ξ just before the Creation phase 
            // ends, then there will be 1Ξ that will go to the main DAO account and 
            // 0.5Ξ that will go to the Extra Balance account.
            //
            // In this case, all the DTH who split immediately after the Creation 
            // phase closes will get exactly 1Ξ/100Ð regardless what they may have 
            // paid for each Ð.
            //
            // The ether in the Extra Balance account can go to the main DAO when the 
            // DAO has spent as much ether as the Extra Balance account has. That 
            // happens by making a proposal to call the payOut() function of the 
            // Extra Balance account with the DAO itself as the beneficiary.
            extraBalance.call.value(msg.value - token)();

            balances[_tokenHolder] += token;
            totalSupply += token;
            weiGiven[_tokenHolder] += msg.value;
            CreatedToken(_tokenHolder, token);

            if (totalSupply >= minTokensToCreate && !isFueled) {
                isFueled = true;
                FuelingToDate(totalSupply);
            }
            return true;
        }
        throw;
    }

    function rewardTeam() returns (bool success) {
        // Reward our team
        // only if DAO is fueled
        if (!isTeamRewarded && isFueled && (msg.sender == teamRewardAccount)) { 
            // TODO: fix real -> uint. Somehow this is converted to real values (((
            // TODO: please see 'tests/scenarios/fuel/run.py' for comments
            // TODO: please run 'fuel' tests to see it fails
            uint teamRewardInTokens = uint((totalSupply / 85.0) * 15.0);

            balances[teamRewardAccount] += teamRewardInTokens;
            totalSupply += teamRewardInTokens;
            isTeamRewarded = true;   // one time only

            CreatedToken(teamRewardAccount, teamRewardInTokens);
            return true;
        }
        return false;
    }

    function refund() noEther {
        if (now > closingTime && !isFueled) {
            // Get extraBalance - will only succeed when called for the first time
            if (extraBalance.balance >= extraBalance.accumulatedInput())
                extraBalance.payOut(address(this), extraBalance.accumulatedInput());

            // Execute refund
            if (msg.sender.call.value(weiGiven[msg.sender])()) {
                Refund(msg.sender, weiGiven[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0;
                weiGiven[msg.sender] = 0;
            }
        }
    }

    function divisor() constant returns (uint divisor) {
        // The number of (base unit) tokens per wei is calculated
        // as `msg.value` * 20 / `divisor`
        // The fueling period starts with a 1:1 ratio
        if (closingTime - 2 weeks > now) {
            return 20;
        // Followed by 10 days with a daily creation rate increase of 5%
        } else if (closingTime - 4 days > now) {
            return (20 + (now - (closingTime - 2 weeks)) / (1 days));
        // The last 4 days there is a constant creation rate ratio of 1:1.5
        } else {
            return 30;
        }
    }
}
