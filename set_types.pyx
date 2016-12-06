import numpy as np
from monte_carlo import (play_service_game, play_fast_four_tiebreak,
                         play_tiebreak)
from collections import namedtuple

SetResults = namedtuple("SetResults", ['final_score', 'points_played',
                                       'num_changes_ends'])

MatchResults = namedtuple("MatchResults", ['set_scores', 'total_points',
                                           'total_changes_ends', 'final_score',
                                           'num_set_changes', 'first_servers'])


def best_of(set_win_fun, p_serve_wins, best_of, final_set_fun=None):

    cur_score = np.zeros(2, dtype=np.int)

    total_points = 0
    total_changes_ends = 0

    cur_server = 0

    set_scores = list()
    set_servers = list()

    while (np.abs(cur_score[0] - cur_score[1]) <=
           best_of - np.sum(cur_score)):

        if np.sum(cur_score) == (best_of - 1):

            # We are in the final set:
            final_set_fun = (set_win_fun if final_set_fun is None else
                             final_set_fun)

            set_results = final_set_fun(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]])

        else:

            set_results = set_win_fun(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]])

        # Bookkeeping
        total_points += set_results.points_played
        total_changes_ends += set_results.num_changes_ends
        set_scores.append(set_results)
        set_servers.append(cur_server)

        # Update state
        set_score = set_results.final_score
        winner = cur_server if np.argmax(set_score) == 0 else 1 - cur_server
        cur_score[winner] += 1

        cur_server = (cur_server if np.sum(set_score) % 2 == 0 else
                      1 - cur_server)

    return MatchResults(final_score=cur_score, set_scores=set_scores,
                        total_points=total_points,
                        total_changes_ends=total_changes_ends,
                        num_set_changes=np.sum(cur_score) - 1,
                        first_servers=set_servers)


def iptl_best_of(set_win_fun, p_serve_wins, best_of, final_set_fun=None):

    cur_score = np.zeros(2, dtype=np.int)

    total_points = 0
    total_changes_ends = 0

    cur_server = 0

    set_scores = list()
    set_servers = list()

    while len(set_scores) < best_of:

        if len(set_scores) == (best_of - 1):

            # We are in the final set:
            final_set_fun = (set_win_fun if final_set_fun is None else
                             final_set_fun)

            set_results = final_set_fun(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]])

        else:

            set_results = set_win_fun(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]])

        # Bookkeeping
        total_points += set_results.points_played
        total_changes_ends += set_results.num_changes_ends
        set_scores.append(set_results)
        set_servers.append(cur_server)

        # Update state
        set_score = set_results.final_score
        winner = cur_server if np.argmax(set_score) == 0 else 1 - cur_server
        cur_score[winner] += set_score[np.argmax(set_score)]
        cur_score[1 - winner] += set_score[1 - np.argmax(set_score)]

        cur_server = (cur_server if np.sum(set_score) % 2 == 0 else
                      1 - cur_server)

    return MatchResults(final_score=cur_score, set_scores=set_scores,
                        total_points=total_points,
                        total_changes_ends=total_changes_ends,
                        num_set_changes=len(set_scores) - 1,
                        first_servers=set_servers)


def play_standard_set(p_serve_wins, has_tiebreak=True, service_game_ad=True):

    points_played = 0
    num_changes_ends = 0

    cur_score = np.zeros(2, dtype=np.int)

    while (not any([x >= 6 for x in cur_score])
           or np.abs(cur_score[0] - cur_score[1]) < 2):

        cur_server = np.sum(cur_score) % 2

        if np.sum(cur_score) % 2 == 1:
            num_changes_ends += 1

        if all([x == 6 for x in cur_score]) and has_tiebreak:

            tb_outcome = play_tiebreak(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]],
                min_points=7, is_ad=True)

            num_changes_ends += np.sum(tb_outcome) // 6

            tb_winner = (cur_server if np.argmax(tb_outcome) == 0 else 1 -
                         cur_server)

            points_played += np.sum(tb_outcome)

            cur_score[tb_winner] += 1

            break

        game_result = play_service_game(p_serve_wins[cur_server],
                                        is_ad=service_game_ad)

        points_played += np.sum(game_result)

        if np.argmax(game_result) == 0:

            cur_score[cur_server] += 1

        else:

            cur_score[1 - cur_server] += 1

    return SetResults(final_score=cur_score, points_played=points_played,
                      num_changes_ends=num_changes_ends)


def play_iptl_set(p_serve_wins, super_shoot_out=False):

    points_played = 0
    num_changes_ends = 0

    cur_score = np.zeros(2, dtype=np.int)

    while (not any([x == 6 for x in cur_score])
           or np.abs(cur_score[0] - cur_score[1]) < 2):

        cur_server = np.sum(cur_score) % 2

        if np.sum(cur_score) % 2 == 1:
            num_changes_ends += 1

        if all([x == 5 for x in cur_score]):

            min_points = 10 if super_shoot_out else 7

            tb_outcome = play_tiebreak(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]],
                min_points=min_points, is_ad=False)

            num_changes_ends += np.sum(tb_outcome) // 6

            tb_winner = (cur_server if np.argmax(tb_outcome) == 0 else 1 -
                         cur_server)

            points_played += np.sum(tb_outcome)

            cur_score[tb_winner] += 1

            break

        game_result = play_service_game(p_serve_wins[cur_server], is_ad=False)

        points_played += np.sum(game_result)

        if np.argmax(game_result) == 0:

            cur_score[cur_server] += 1

        else:

            cur_score[1 - cur_server] += 1

    return SetResults(final_score=cur_score, points_played=points_played,
                      num_changes_ends=num_changes_ends)


def play_fast_four_set(p_serve_wins):

    points_played = 0
    num_changes_ends = 0

    cur_score = np.zeros(2, dtype=np.int)

    while not any([x > 3 for x in cur_score]):

        cur_server = np.sum(cur_score) % 2

        if np.sum(cur_score) % 2 == 1:
            num_changes_ends += 1

        if all([x == 3 for x in cur_score]):

            tb_result = play_fast_four_tiebreak(
                [p_serve_wins[cur_server], p_serve_wins[1 - cur_server]])

            # Only one change of ends in the tiebreak
            if np.sum(tb_result) > 4:
                num_changes_ends += 1

            winner = np.argmax(tb_result)

            points_played += np.sum(tb_result)

            cur_score[winner] += 1

            break

        cur_serve_prob = p_serve_wins[cur_server]

        game_score = play_service_game(
            cur_serve_prob, min_points=4, is_ad=False)

        points_played += np.sum(game_score)

        winner = cur_server if np.argmax(game_score) == 0 else 1 - cur_server

        cur_score[winner] += 1

    return SetResults(final_score=cur_score, points_played=points_played,
                      num_changes_ends=num_changes_ends)


def super_tb(p_serve_wins):

    result = play_tiebreak(p_serve_wins, min_points=10)

    return SetResults(final_score=result, points_played=np.sum(result),
                      num_changes_ends=np.sum(result) // 6)
