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

// if in other folder:
// solc DAO=/home/tonykent/DAO vdice_proposal.sol

import "./DAO.sol";
import "./vdice.sol";

// 1 - Set all variables
// 2 - Deploy your Proposal 
// 3 - Post your proposal on a forum (In your post, please include the address of the deployed 
//     contract, a link to its source code, compilation instructions and the date, time and link 
//     of the Google hangout (preferred method) you will use to confirm your identity. A link to 
//     the details of your proposal should also be included).
// 4 - Wait for verification
// 5 - Curators will add your address to white-list
// 6 - You can call 'newProposal'
// 7 - Wait for voting
// 8 - executeProposal will be called -> it will call your sign() function if Proposal is accepted
contract SampleProposal {

    uint public totalCosts;   // amount of money to invest from DaoCasino
    uint public oneTimeCosts; // amount of money to move to contractor right when this proposal
                              // is accepted
    uint public dailyCosts;   // amount of money contractor can get each day from this contract

    // the entity that has rights to withdraw ether to perform its project.
    address public contractor;

    bytes32 public hashOfTheTerms;
    uint public minDailyCosts;
    uint public paidOut;

    uint public dateOfSignature;

    // the DAO that gives ether to the Contractor. It signs off
    // the Proposal, can adjust daily withdraw limit or even fire the
    // Contractor.
    DAO public client; 
    address public vdiceGameAddress;
    Dice public vdiceGame;

    bool public promiseValid = false; // is signed by DaoCasino?

    modifier callingRestriction {
        if (promiseValid) {
            if (msg.sender != address(client))
                throw;
        } else if (msg.sender != contractor) {
                throw;
        }
        _
    }

    modifier onlyClient {
        if (msg.sender != address(client))
            throw;
        _
    }

    function SampleProposal(
        address _contractor,
        address _vdiceGameAddress,
        bytes32 _hashOfTheTerms,
        uint _totalCosts,
        uint _oneTimeCosts,
        uint _minDailyCosts
    ) {
        contractor = _contractor;

        if(0==_vdiceGameAddress){
            throw;
        }
        vdiceGameAddress = _vdiceGameAddress;

        vdiceGame = Dice(_vdiceGameAddress);

        hashOfTheTerms = _hashOfTheTerms;
        totalCosts = _totalCosts;
        oneTimeCosts = _oneTimeCosts;
        minDailyCosts = _minDailyCosts;
        dailyCosts = _minDailyCosts;
    }
    
    // This will be called by DAO from within executeContract() method.
    // !!! 
    //   In order to do that -> set '0x2ca15122' as a _transactionData in 'newProposal' and 
    // 'executeProposal' calls.
    //   see here - https://github.com/slockit/DAO/wiki/PFOffer-Workflow
    // !!!
    function sign() {
        if (msg.value < totalCosts || dateOfSignature != 0)
            throw;
        if (msg.value < oneTimeCosts){
            throw; 
        }
        if (!contractor.send(oneTimeCosts))
            throw;
        client = DAO(msg.sender);
        dateOfSignature = now;
        promiseValid = true;

        // Send funds to game
        // You can also use getDailyPayment() instead
        uint sendToGame = (msg.value - oneTimeCosts);    // must be positive (see check above)
        uint safeGas = 25000;
        if(!vdiceGame.proposalIsAccepted.gas(safeGas).value(sendToGame)()){
            throw;
        }

        /*
        // Add game to store
        uint gameID = client.addGameToStore.gas(safeGas)(address(this));
        if(0==gameID){
            throw;
        }
        */
    }

    // "fire the contractor"
    function returnRemainingMoney() onlyClient {
        if (client.receiveEther.value(this.balance)())
            promiseValid = false;
    }

    function setDailyCosts(uint _dailyCosts) onlyClient {
        if (dailyCosts >= minDailyCosts)
            dailyCosts = _dailyCosts;
    }

    function getDailyPayment() {
        if (msg.sender != contractor)
            throw;
        uint amount = (now - dateOfSignature) / (1 days) * dailyCosts - paidOut;
        if (contractor.send(amount))
            paidOut += amount;
    }

    function updateClientAddress(DAO _newClient) callingRestriction {
        client = _newClient;
    }

    // Fallback function
    function (){
        throw; // this is a business contract, no donations
    }
}
