/* How to Add already existing Game to DaoCasino?

**Please see vdice.sol and vdice_proposal.sol**

1. Deploy your game contract with DaoCasino as a client. Game must reward DaoCasino. 
2. Write proposal with "Add my game at 0xccaxadfadfbababababa address to Store" description and don't forget to include contract source code. You can even ask for JackPot money as an investment.
The proposal can move money to your game directly or can move it to contractor (you).
3. When proposal will be accepted (see diagram below) - proposal's sign() will be called and money (if required) will be moved from DaoCasino to proposal.  
4. sign() must call addGameToStore(). 
5. DaoCasino's addGameToStore() 
*/

// if in orher folder:
// solc DAO=/home/tonykent/DAO vdice.sol

import "./DAO.sol";

/// @notice Different helpers function go here
library Helpers {
     function parseInt(string _a) internal returns (uint) {
          return parseInt(_a, 0);
     }

     function parseInt(string _a, uint _b) internal returns (uint) {
          bytes memory bresult = bytes(_a);
          uint mint = 0;
          bool decimals = false;
          for (uint i=0; i<bresult.length; i++){
               if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                    if (decimals){
                         if (_b == 0) break;
                         else _b--;
                    }
                    mint *= 10;
                    mint += uint(bresult[i]) - 48;
               } else if (bresult[i] == 46) decimals = true;
          }
          return mint;
     }
}

/// @notice Code is by vdice.io originally. This is 50% win contract.
/// DaoCasino team has improved it a bit
/// Money Flow: If user loses:
///  100% user loss -> 1 wei to user + (100% - 1 wei) to profit
///  100% profit -> 2% to platform + 98% to game profit
///  100% game profit -> 5% to game owner + 95% to game JackPot
contract Dice {
     uint public pwin = 5000; //probability of winning (10000 = 100%)
     uint public edge = 200; //edge percentage (10000 = 100%)
     uint public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
     uint public minBet = 1 finney;
     uint public daoEdge = 200; // edge percentage (10000 = 100%)
     uint public ownerEdge = 50; //edge percentage (10000 = 100%)
     uint constant safeGas = 25000;

     address owner;
     address public daoCasinoAddress;
     DAO daoCasino;
     
     address public platformAddress;

     bool public isStopped = true; // until 'proposalIsAccepted' is called

     struct Bet {
          address user;
          uint bet; // amount
          uint roll; // result
          uint fee; 

          address referer;
          address platform;
     }
     mapping (bytes32 => Bet) bets;
     bytes32[] betsKeys;

     uint public amountWagered = 0;
     int public profit = 0;
     int public takenProfit = 0;
     int public ownerProfit = 0;

     function Dice(
          uint pwinInitial, 
          uint edgeInitial, 
          uint maxWinInitial, 
          uint minBetInitial, 
          uint ownerEdgeInitial, 
          address _daoCasinoAddress,
          address _platformAddress) 
     {
          pwin = pwinInitial;
          edge = edgeInitial;
          maxWin = maxWinInitial;
          minBet = minBetInitial;
          ownerEdge = ownerEdgeInitial;

          owner = msg.sender;

          daoCasinoAddress = _daoCasinoAddress;
          platformAddress = _platformAddress;
          daoCasino = DAO(_daoCasinoAddress);
     }

     function bet(address referer, address platform) {
          // 1 - Check all params
          if (isStopped) { 
               throw;
          }

          uint randFee = daoCasino.getRandOraclizedPrice();
          if (msg.value < randFee) { 
               throw;
          }

          // 2 - Out of money?
          uint betValue = msg.value - randFee;
          if ((((betValue * ((10000 - edge) - pwin)) / pwin ) > (maxWin * getBankroll()) / 10000) 
                    ||
               (betValue < minBet)) 
          {
               throw;    // error
          }

          // 3 - Send query to RNG 
          bytes32 myid = daoCasino.generateRandOraclized.value(randFee)();
          bets[myid] = Bet(msg.sender, betValue, 0, randFee, referer, platform);
     }

     function numBets() constant returns(uint) {
          return betsKeys.length;
     }

     function minBetAmount() constant returns(uint) {
          uint randFee = daoCasino.getRandOraclizedPrice();
          return randFee + minBet;
     }

     function safeSend(address addr, uint value) internal {
          if (!(addr.call.gas(safeGas).value(value)())){
               ownerProfit += int(value);
          }
     }

     /// @notice This method must split the reward into 4 separate streams
     /// We are not doing that in DaoCasino
     function sendRewardToDao(Bet bet, uint value) internal {
          address player = bet.user;
          address referer = bet.referer;
          address platform = bet.platform;

          uint amount = value / 4;
          if(!(player.call.gas(safeGas).value(amount)())){
               throw;     
          }
          if(!(referer.call.gas(safeGas).value(amount)())){
               throw; 
          }
          if(!(platform.call.gas(safeGas).value(amount)())){
               throw;
          }

          // calling DAOs method that will receive ether
          daoCasino.receiveGameReward.gas(safeGas).value(amount)(player,referer,platform);
     }

     // this is called by a source of random numbers (Dao.Casino itself)
     function __callback(bytes32 myid, string result, bytes proof) {
          if (msg.sender != daoCasinoAddress) {
               throw;
          }

          // 1 - Check params
          Bet thisBet = bets[myid];
          if (thisBet.bet>0) {
               if ((isStopped != false)|| (((thisBet.bet * ((10000 - edge) - pwin)) / pwin ) > maxWin * getBankroll() / 10000)) 
               {
                    //bet is too big (bankroll may have changed since the bet was made)
                    safeSend(thisBet.user, thisBet.bet);
                    return;
               }

               // 2 - Calculate roll
               uint roll = Helpers.parseInt(result);
               if (roll<1){
                    safeSend(thisBet.user, thisBet.bet);
                    return;    
               }

               // TODO: truncates last one!!!
               roll = roll % 10000;

               if (roll<1 || roll>10000){
                    safeSend(thisBet.user, thisBet.bet);
                    return;    
               }

               // 3 - Save roll
               bets[myid].roll = roll;

               // 4 - Send money
               int profitDiff;
               if (roll-1 < pwin) { //win
                    uint winAmount = (thisBet.bet * (10000 - edge)) / pwin;
                    safeSend(thisBet.user, winAmount);

                    // will be negative?
                    profitDiff = int(thisBet.bet - winAmount);
               } else { //lose
                    safeSend(thisBet.user, 1);
                    profitDiff = int(thisBet.bet) - 1;
               }

               // immediately send reward to DAO in case of user loss
               if(profitDiff>0){
                    int daoReward = (profitDiff*int(daoEdge))/10000;
                    sendRewardToDao(thisBet, uint(daoReward));

                    profitDiff -= daoReward;
               }
               
               // send profit to game owner 
               int addOwnerProfit = (profitDiff*int(ownerEdge))/10000;
               ownerProfit += addOwnerProfit;
               profitDiff -= addOwnerProfit;

               profit += profitDiff;
               amountWagered += thisBet.bet;
          }
     }

     function getBet(uint id) constant returns(address, uint, uint, uint) {
          if(id<betsKeys.length)
          {
               bytes32 betKey = betsKeys[id];
               return (bets[betKey].user, bets[betKey].bet, bets[betKey].roll, bets[betKey].fee);
          }
     }

     function getStatus() constant returns(uint, uint, uint, uint, uint, uint, int, uint, uint) {
          return (getBankroll(), pwin, edge, maxWin, minBet, amountWagered, profit, getMinInvestment(), betsKeys.length);
     }

     function stopContract() {
          if (owner != msg.sender) throw;
          isStopped = true;
     }

     function resumeContract() {
          if (owner != msg.sender) throw;
          isStopped = false;
     }

     function ownerTakeProfit() {
          if (owner != msg.sender) throw;

          owner.send(uint(ownerProfit));
          ownerProfit = 0;
     }

     function getMinInvestment() constant returns(uint) {
          return 0;
     }

     function getBankroll() constant returns(uint) {
          uint bankroll = uint(profit+ownerProfit-takenProfit);
          if (this.balance < bankroll){
               log0("bankroll_mismatch");
               bankroll = this.balance;
          }
          return bankroll;
     }

     // this is called from 'vdice_proposal' contract when proposal is accepted by DaoCasino
     // it gives us money for JackPot and we can start our game!
     function proposalIsAccepted() returns(bool){
          // TODO: get money here!

          isStopped = false;

          return true;
     }

     function() {
          // if you just send your money to that contract
          //bet();

          throw;
     }
}
