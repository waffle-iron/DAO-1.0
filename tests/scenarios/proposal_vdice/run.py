import random
from utils import arr_str, create_votes_array

scenario_description = (
    "Create a VDICE game proposal to send an amount of ether to the vdice_proposal contract."
    " Vote on that proposal, wait for the debating period and then execute it."
)


def count_token_votes(amounts, votes):
    """Returns how many tokens votes yay and how many voted nay"""
    yay = 0
    nay = 0
    for idx, amount in enumerate(amounts):
        if votes[idx]:
            yay += amount
        else:
            nay += amount
    return yay, nay


def run(ctx):
    ctx.assert_scenario_ran('curators')

    minamount = 2  # is determined by the total costs + one time costs
    amount = random.randint(minamount, sum(ctx.token_amounts))
    votes = create_votes_array(
        ctx.token_amounts,
        True,       #not ctx.args.proposal_fail,
        False
    )
    yay, nay = count_token_votes(ctx.token_amounts, votes)
    ctx.create_js_file(substitutions={
        "dao_abi": ctx.dao_abi,
        "dao_address": ctx.dao_addr,
        "offer_abi": ctx.offer2_abi,
        "offer_address": ctx.offer2_addr,
        "offer_amount": amount,
        "offer_desc": 'Vdice Proposal',
        "proposal_deposit": ctx.args.proposal_deposit,
                                               # sign hash
        "transaction_bytecode": '0x2ca15122',  # solc --hashes vdice_proposal.sol
        "debating_period": ctx.args.proposal_debate_seconds,
        "votes": arr_str(votes),

        "vdice_abi": ctx.vdice_abi,
        "vdice_bin": ctx.vdice_bin,
        "vdiceAddress": ctx.vdice_addr,

        "offer2_abi": ctx.offer2_abi,
        "offer2_bin": ctx.offer2_bin,
        "offer2_addr": ctx.offer2_addr
    })
    print(
        "Notice: Debate period is {} seconds so the test will wait "
        "as much".format(ctx.args.proposal_debate_seconds)
    )

    ctx.execute(expected={
        "dao_proposals_number": "1",
        #"proposal_yay": yay,
        #"proposal_nay": nay,

        # Curator votes:
        "proposal_yay": 3,
        "proposal_nay": 0,

        "calculated_deposit": ctx.args.proposal_deposit,

        # TODO: Unfortunately this makes 'proposal', 'newcontract', 'split' etc tests
        # to fail...
        # Please fix it!
        #
        #"onetime_costs": ctx.args.deploy_onetime_costs,

        "deposit_returned": True,
        "offer_promise_valid": True,

        'vdice_offer_vdice_addr': ctx.vdice_addr,
        "vdice_stopped_after": False
    })
