var dao = web3.eth.contract($dao_abi).at('$dao_address');
var prop_id = attempt_proposal(
    dao, // DAO in question
    dao.address, // recipient
    proposalCreator, // proposal creator
    0, // proposal amount in ether
    'Changing proposal deposit', // description
    '$transaction_bytecode', //bytecode
    $debating_period, // debating period
    $proposal_deposit, // proposal deposit in ether
    false // whether it's a split proposal or not
);

// in this scenario ONLY CURATORS vote for the change
for (i = 0; i < 2; i++) {
    dao.vote.sendTransaction(
        prop_id,
        true,
        {
            from: eth.accounts[i],
            gas: 1000000
        }
    );
}

checkWork();

for (i = 2; i < 5; i++) {
     dao.blockProposal.sendTransaction(
        prop_id,
        {
            from: eth.accounts[i],
            gas: 1000000
        }
     );
}
checkWork();

setTimeout(function() {
    miner.stop();

    attempt_execute_proposal(
        dao, // target DAO
        prop_id, // proposal ID
        '$transaction_bytecode', // transaction bytecode
        curator, // proposal creator
        true, // should the proposal be closed after this call?
        false // should the proposal pass?
    );
    addToTest('deposit_after_vote', parseInt(dao.proposalDeposit()));
    addToTest('dao_total_supply', parseInt(web3.fromWei(dao.totalSupply()).ceil()));

    addToTest('proposal_yay', parseInt(web3.fromWei(dao.proposals(prop_id)[9])));
    addToTest('proposal_nay', parseInt(web3.fromWei(dao.proposals(prop_id)[10])));

    addToTest('blocking_count', parseInt(web3.fromWei(dao.proposals(prop_id)[11])));

    testResults();
}, $debating_period * 1000);
miner.start(1);
