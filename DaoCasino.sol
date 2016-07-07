/*
This file is part of the DaoCasino.

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

contract DAOCasinoInterface {
    function getRewardAddress() returns (address rewardAddress);

// Rand:
    /// @notice Before calling rand - 
    function getRandOraclizedPrice() returns (uint priceInWei);

    /// @notice Add query for oracle to generate random number.
    /// Call it like this:
    ///   bytes32 randId = daoCasino.generateRandOraclized.value(price)();
    /// Will call in your contract:
    ///   function __callback(bytes32 myid, string result, bytes proof);
    /// @return ID of "get random" query. Call getRandOraclized and pass that ID. 
    function generateRandOraclized() returns (bytes32 randId);

// Referrals:
    // Client => Referrer
    // Referrer - An account, that receives a percentage of referral fees.
    mapping (address => address) referrers;

    /// @notice Must be called by a player. 
    /// 1) If player is alredy has associated referrer -> throw
    /// 2) If player has no associated referrer, but already played -> throw
    /// @return If true -> everything is OK
    function setReferrer(address player, address referrer) returns (bool isSet);
}

// TODO: 
contract Platform {
    struct Game {
        uint proposalID;      // see proposals array
        string name;
        string description;
        string urlPic;
        bool showInStore;

        // TODO: ...
    }

    Game[] public games;

    /// @notice If you have already existing Game: 
    /// 1) Make a proposal "Please add my game to platform" (pass fee to that contract)
    /// 2) Wait for proposal to be passed
    /// 3) Call addGameToStore with proposal ID 
    ///
    /// If you want to develop new game
    /// 1) Create 1st proposal "Give me money to develop cool new game"(return investment to that contract)
    /// 2) Create 2nd proposal "Please add my game to platform" (pass fee to that contract)
    /// 
    function addGameToStore(
        uint _proposalID, 
        string _name, 
        string _description, 
        string _urlPic) returns (uint gameID);

    function removeGameFromStore(uint _gameID) returns (bool success);
}

// TODO: 
contract DAOCasino is DAOCasinoInterface {
    function getRandOraclizedPrice() returns (uint priceInWei) {
        priceInWei = 0;
        return;
    }

    function generateRandOraclized() returns (bytes32 randId){
        randId = 0;
        return;
    }

    function setReferrer(address player, address referrer) returns (bool isSet){
        isSet = false;
        return;
    }
}


