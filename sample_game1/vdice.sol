
// example:
// solc DAO=/home/tonykent/DAO vdice.sol
import "DAO/DaoCasino.sol";

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
     uint public platformEdge = 200; // edge percentage (10000 = 100%)
     uint public ownerEdge = 50; //edge percentage (10000 = 100%)
     uint constant safeGas = 25000;

     address owner;
     address public daoCasinoAddress;
     DAOCasinoInterface daoCasino;

     bool public isStopped = true; // until 'proposalIsAccepted' is called

     struct Bet {
          address user;
          uint bet; // amount
          uint roll; // result
          uint fee; 
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
          //uint maxInvestorsInitial, 
          uint ownerEdgeInitial, 
          //uint divestFeeInitial,
          address _daoCasinoAddress) 
     {
          pwin = pwinInitial;
          edge = edgeInitial;
          maxWin = maxWinInitial;
          minBet = minBetInitial;
          ownerEdge = ownerEdgeInitial;

          owner = msg.sender;

          daoCasinoAddress = _daoCasinoAddress;
          daoCasino = DAOCasinoInterface(_daoCasinoAddress);
     }

     function bet() {
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
          bets[myid] = Bet(msg.sender, betValue, 0, randFee);
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

               // immediately send reward to platform in case of user loss
               if(profitDiff>0){
                    int platformReward = (profitDiff*int(platformEdge))/10000;
                    address platformRewardAccount = daoCasino.getCasinoRewardAddress();

                    safeSend(platformRewardAccount, uint(platformReward));
                    profitDiff -= platformReward;
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
     function proposalIsAccepted(){
          // TODO: get invested in us by DaoCasino money. Check msg.value

          isStopped = false;
     }

     function() {
          // if you just send your money to that contract
          //bet();

          throw;
     }
}
