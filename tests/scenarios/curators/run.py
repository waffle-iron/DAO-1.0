import random
from utils import constrained_sum_sample_pos, arr_str

scenario_description = (
    "We are adding more curators. Only DAO deployer could do that"
)


def run(ctx):
    ctx.assert_scenario_ran('fuel')

    creation_secs = ctx.remaining_time()

    ctx.create_js_file(substitutions={
            "dao_abi": ctx.dao_abi,
            "dao_address": ctx.dao_addr,
            "wait_ms": (creation_secs-3)*1000,
        }
    )

    print("Adding new curators")

    ctx.execute(expected={
        "curators_count_after": 3,
    })
