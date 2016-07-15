from utils import calculate_bytecode

scenario_description = (
    "Someone has proposed bad thing. So we as a DAO Token Holders want "
    "to block that proposal"
)


def run(ctx):
    ctx.assert_scenario_ran('curators')

    bytecode = calculate_bytecode(
        'changeProposalDeposit',
        ('uint256', ctx.args.deposit_new_value)
    )
    ctx.create_js_file(substitutions={
            "dao_abi": ctx.dao_abi,
            "dao_address": ctx.dao_addr,
            "proposal_deposit": ctx.args.proposal_deposit,
            "transaction_bytecode": bytecode,
            "debating_period": ctx.args.deposit_debate_seconds
        }
    )
    print(
        "Notice: Debate period is {} seconds so the test will wait "
        "as much".format(ctx.args.proposal_debate_seconds)
    )

    adjusted_amounts = (
        [x/1.5 for x in ctx.token_amounts]
        if ctx.scenario_uses_extrabalance() else ctx.token_amounts
    )

    adjusted_supply = (
        (ctx.total_supply / 1.5)
        if ctx.scenario_uses_extrabalance() else ctx.total_supply
    )

    blocking_tokens_count =  adjusted_amounts[2] + adjusted_amounts[3] + adjusted_amounts[4];
    print("Blocking count must be: {}".format(blocking_tokens_count))
    print("Total supply is: {}".format(adjusted_supply))

    ctx.execute(expected={
        "dao_total_supply": ctx.total_supply,

        "proposal_yay": 2,    # all curators voted 'Yes'
        "proposal_nay": 0,

        "blocking_count": blocking_tokens_count,

        # Deposit should not be changed because proposal didn't pass
        #"deposit_after_vote": ctx.args.deposit_new_value,
        "deposit_after_vote": 20
    })
