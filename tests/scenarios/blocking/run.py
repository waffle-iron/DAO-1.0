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

    ctx.execute(expected={
        "deposit_after_vote": ctx.args.deposit_new_value,
        "dao_total_supply": ctx.total_supply,

        "proposal_yay": 3,    # all curators voted 'Yes'
        "proposal_nay": 0,

        "blocking_count": 2
    })
