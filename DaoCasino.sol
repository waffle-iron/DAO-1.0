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
    struct RandOraclized{
         address user;
         uint result;    
         bool isRandGenerated;
    }
    mapping (uint => RandOraclized) rands;

// Rand:
    /// @notice Add query for oracle to generate random number.
    /// @return ID of "get random" query. Call getRandOraclized and pass that ID. 
    function generateRandOraclized() returns (uint randId);

    /// @notice Get random number
    /// @return isRandGenerated - if false -> please wait more
    function getRandOraclized(uint randId) constant returns(bool isRandGenerated, uint randValue);

// Referalls:
    // Client => Referrer
    // Referrer - A Member account, that receives a percentage of referral fees.
    mapping (address => address) referrals;

    /// @notice Can be called only by TheDAO to mitigate risk of cheating
    /// @return If true -> everything is OK, if false -> this address was already set
    function setReferral(address client, address referrer) /*onlyCurator*/ returns (bool isSet);
}

contract DAOCasino is DAOCasinoInterface {

    function generateRandOraclized() returns (uint randId){
        randId = 0;
        return;
    }

    function getRandOraclized(uint randId) constant returns(bool isRandGenerated, uint randValue){
        isRandGenerated = false;
        randValue = 0;
        return;
    }

    function setReferral(address client, address referrer) /*onlyCurator*/ returns (bool isSet){
        isSet = false;
        return;
    }
}


