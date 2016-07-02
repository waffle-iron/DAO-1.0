import random
from utils import constrained_sum_sample_pos, arr_str


scenario_description = (
    "During the fueling period of the DAO, send enough ether from all "
    "accounts to create tokens and then assert that the user's balance is "
    "indeed correct and that the minimum fueling goal has been reached"
)


def run(ctx):
    ctx.assert_scenario_ran('deploy')

    creation_secs = ctx.remaining_time()
    ctx.total_supply = (
        ctx.args.deploy_min_tokens_to_create + random.randint(1, 100)
    )
    ctx.token_amounts = constrained_sum_sample_pos(
        len(ctx.accounts), ctx.total_supply
    )
    ctx.create_js_file(substitutions={
            "dao_abi": ctx.dao_abi,
            "dao_address": ctx.dao_addr,
            "wait_ms": (creation_secs-3)*1000,
            "amounts": arr_str(ctx.token_amounts)
        }
    )

    print("MIN TOKENS TO CREATE: {}".format(ctx.args.deploy_min_tokens_to_create))
    print("AMOUNTS: {}".format(arr_str(ctx.token_amounts)))

    print(
        "Notice: Fueling period is {} seconds so the test will wait "
        "as much".format(creation_secs)
    )

    adjusted_amounts = (
        [x/1.5 for x in ctx.token_amounts]
        if ctx.scenario_uses_extrabalance() else ctx.token_amounts
    )

    adjusted_supply = (
        (ctx.total_supply / 1.5)
        if ctx.scenario_uses_extrabalance() else ctx.total_supply
    )

    # Calculate extra 15% team reward
    # TODO: if we convert to int -> test will fail like that:
    # ERROR: Expected 95 for 'total_supply' but got 95.2941176471
    team_reward = int(((ctx.total_supply) / 85.0) * 15.0)

    # TODO: uncomment
    #adjusted_supply += team_reward

    # TODO: uncomment
    #adjusted_amounts[0] += team_reward

    ctx.execute(expected={
        "dao_fueled": True,
        "total_supply": adjusted_supply,
        "balances": adjusted_amounts,
        "user0_after": adjusted_amounts[0]
    })
