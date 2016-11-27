"""This script runs the paper combinations of bonus and malus for different
tours."""

import pandas as pd
from tqdm import tqdm
from simulate import run_trials, get_systems, spw_from_bonus_malus


def intervals():

    # Bonuses
    bonuses = {'wta_hard_clay': [1.05, 1.10, 1.15, 1.20],
               'wta_grass': [1.1, 1.15, 1.2, 1.25],
               'atp_hard': [1.2, 1.25, 1.3],
               'atp_grass': [1.25, 1.3, 1.35]}

    # Malus same for all
    maluses = {x: [0.0, 0.05, 0.1, 0.15] for x in bonuses}

    bonus_malus = {x: {'bonus': bonuses[x], 'malus': maluses[x]} for x in
                   bonuses}

    return bonus_malus


def run_combinations(bonus_malus_dict, num_trials, match_functions):

    results = list()

    for cur_type in tqdm(bonus_malus_dict):

        cur_maluses = bonus_malus_dict[cur_type]['malus']
        cur_bonuses = bonus_malus_dict[cur_type]['bonus']

        # Get the combinations

        for cur_malus in cur_maluses:

            for cur_bonus in cur_bonuses:

                spw_1, spw_2 = spw_from_bonus_malus(cur_bonus, cur_malus)

                for format_name, match_fn in match_functions.items():

                    cur_results = run_trials(match_fn, spw_1, spw_2,
                                             num_trials=num_trials)

                    cur_results['format'] = format_name
                    cur_results['group_name'] = cur_type

                    results.append(cur_results)

    return pd.concat(results, ignore_index=True)


if __name__ == '__main__':

    import sys
    import argparse

    systems = get_systems()

    parser = argparse.ArgumentParser()
    parser.add_argument('--match-format', required=True, type=str,
                        help='Any one of {} or "all" to run all of them.'.format(
                            list(systems.keys())))
    parser.add_argument('--num-trials', default=int(1e4), type=int)
    args = parser.parse_args()

    if args.match_format not in systems:

        print('Match format {} is unknown. Please choose from:'.format(
            args.match_format))

        for system_name in list(systems.keys()):
            print(system_name)

        print('Or specify "all" to run all available formats.')

        exit(1)

    b_m_dict = intervals()

    if args.match_format == 'all':

        results = run_combinations(b_m_dict, args.num_trials, systems)

    else:

        results = run_combinations(
            b_m_dict, args.num_trials,
            {args.match_format: systems[args.match_format]})

    results.to_csv(sys.stdout)
