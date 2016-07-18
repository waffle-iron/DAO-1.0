checkWork();

var dao = web3.eth.contract($dao_abi).at('$dao_address');

setTimeout(function() {
    miner.stop();

    dao.addCuratorToWhitelist.sendTransaction(
        eth.accounts[1],
         {
             from:eth.accounts[0],
             to: dao.address,
             gas:200000,
             value:web3.toWei(20, "ether")
         }
    );

    dao.addCuratorToWhitelist.sendTransaction(
        eth.accounts[3],
         {
             from:eth.accounts[0],
             to: dao.address,
             gas:200000,
             value:web3.toWei(20, "ether")
         }
    );

    dao.changeCurator.sendTransaction(
        eth.accounts[3],
        eth.accounts[2],
         {
             from:eth.accounts[0],
             to: dao.address,
             gas:200000,
             value:web3.toWei(20, "ether")
         }
    );

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
