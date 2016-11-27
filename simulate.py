import pyximport; pyximport.install()
import numpy as np
import pandas as pd
import set_types


def get_systems():

    final_set_no_tb = lambda win_probs: set_types.play_standard_set(
        win_probs, has_tiebreak=False)

    final_set_with_tb = lambda win_probs: set_types.play_standard_set(
        win_probs, has_tiebreak=True)

    system_4 = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_standard_set, [spw_1, spw_2],
        5, final_set_fun=final_set_no_tb)

    system_5 = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_standard_set, [spw_1, spw_2],
        3, final_set_fun=final_set_no_tb)

    system_6 = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_standard_set, [spw_1, spw_2],
        5, final_set_fun=final_set_with_tb)

    system_7 = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_standard_set, [spw_1, spw_2],
        3, final_set_fun=final_set_with_tb)

    system_8 = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_standard_set, [spw_1, spw_2],
        3, final_set_fun=set_types.super_tb)

    system_9 = lambda spw_1, spw_2: set_types.best_of(
        lambda win_probs:
        set_types.play_standard_set(win_probs, service_game_ad=False),
        [spw_1, spw_2],
        3, final_set_fun=set_types.super_tb)

    fast_four_singles = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_fast_four_set, [spw_1, spw_2], 3)

    fast_four_doubles = lambda spw_1, spw_2: set_types.best_of(
        set_types.play_fast_four_set, [spw_1, spw_2], 3,
        final_set_fun=set_types.super_tb)

    all_systems = {'atp_wimbledon': system_4, 'wta_wimbledon': system_5,
                   'atp_us_open': system_6, 'wta_us_open': system_7,
                   'mixed_doubles_fo': system_8, 'doubles': system_9,
                   'fast_four_singles': fast_four_singles,
                   'fast_four_doubles': fast_four_doubles}

    return all_systems


def run_trials(match_fn, spw_1, spw_2, num_trials=int(1e4)):

    results = list()

    for i in range(num_trials):

        first_server = np.random.choice([0, 1])

        cur_results = dict()

        if first_server == 0:

            match_result = match_fn(spw_1, spw_2)
            cur_results['better_won'] = (match_result.final_score[0] >
                                        match_result.final_score[1])

        else:

            match_result = match_fn(spw_2, spw_1)
            cur_results['better_won'] = (match_result.final_score[0] <
                                        match_result.final_score[1])

        cur_results.update(
            {'bonus': spw_1 + spw_2, 'malus': spw_1 - spw_2, 'total_points':
            match_result.total_points, 'total_changes_of_ends':
            match_result.total_changes_ends, 'total_set_changes':
             match_result.num_set_changes, 'spw_1': spw_1, 'spw_2': spw_2})

        results.append(cur_results)

    results = pd.DataFrame(results)

    return results


def spw_from_bonus_malus(bonus, malus):

    spw_1 = (bonus + malus) / 2
    spw_2 = (bonus - malus) / 2

    return spw_1, spw_2


if __name__ == '__main__':

    import sys
    import argparse

    systems = get_systems()

    parser = argparse.ArgumentParser()
    parser.add_argument('--match-format', required=True, type=str,
                        help='Any one of {}'.format(list(systems.keys())))
    parser.add_argument('--bonus', required=True, type=float)
    parser.add_argument('--malus', required=True, type=float)
    parser.add_argument('--num-trials', default=int(1e4), type=int)
    args = parser.parse_args()

    if args.match_format not in systems:

        print('Match format {} is unknown. Please choose from:'.format(
            args.match_format))

        for system_name in list(systems.keys()):
            print(system_name)

        print('Or specify "all" to run all available systems.')

        exit(1)

    spw_1, spw_2 = spw_from_bonus_malus(args.bonus, args.malus)

    if args.match_format == 'all':

        results = list()

        for system_name, fn in systems.items():

            cur_results = run_trials(fn, spw_1, spw_2, args.num_trials)
            cur_results['format'] = system_name

            results.append(cur_results)

        results = pd.concat(results, ignore_index=True)

    else:

        results = run_trials(systems[args.match_format], spw_1, spw_2,
                             args.num_trials)

        results['format'] = args.match_format

    results.to_csv(sys.stdout)
