
# How to Add already existing Game to DaoCasino?

**Please see vdice.sol and vdice_proposal.sol**

1. Deploy your game contract with DaoCasino as a client. Game must reward DaoCasino. 
2. Write proposal with "Add my game at 0xccaxadfadfbababababa address to Store" description and don't forget to include contract source code. You can even ask for JackPot money as an investment.
The proposal can move money to your game directly or can move it to contractor (you).
3. When proposal will be accepted (see diagram below) - proposal's sign() will be called and money (if required) will be moved from DaoCasino to proposal.  
4. sign() must call your game contract method which will then call addGameToStore(). 
5. DaoCasino's addGameToStore() 
