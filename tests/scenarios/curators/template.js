checkWork();

var dao = web3.eth.contract($dao_abi).at('$dao_address');

setTimeout(function() {
    miner.stop();

    // 1 - add 2 new curators
    for(var i=1; i<=2; ++i){
         dao.addCuratorToWhitelist.sendTransaction(
             eth.accounts[i],
              {
                  from:eth.accounts[0],
                  to: dao.address,
                  gas:200000,
                  value:web3.toWei(20, "ether")
              }
         );
    }

    checkWork();

    // 2 - should not add curator if tx is from someone else than dao_deployer
    dao.addCuratorToWhitelist.sendTransaction(
        eth.accounts[4],
         {
             from:eth.accounts[1],
             to: dao.address,
             gas:200000,
             value:web3.toWei(20, "ether")
         }
    );

    addToTest('curators_count_after',dao.curatorsCount());

    testResults();
}, $wait_ms);

console.log("Wait for end of curators population");
miner.start(1);
