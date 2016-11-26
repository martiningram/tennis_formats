import numpy as np


def player_wins_point(p_win_serve):

    return np.random.rand() <= p_win_serve


def ad_win_condition(cur_score, min_points):

    return (no_ad_win_condition(cur_score, min_points)
            and np.abs(cur_score[0] - cur_score[1]) >= 2)


def no_ad_win_condition(cur_score, min_points):

    return any([x >= min_points for x in cur_score])


def play_service_game(p_win_serve, min_points=4, is_ad=True):

    cur_score = np.zeros(2, dtype=np.int)

    condition = ad_win_condition if is_ad else no_ad_win_condition

    while not condition(cur_score, min_points):

        if player_wins_point(p_win_serve):

            cur_score[0] += 1

        else:

            cur_score[1] += 1

    return cur_score


def play_fast_four_tiebreak(serve_win_probs):

    cur_score = np.zeros(2, dtype=np.int)

    while not any([x == 5 for x in cur_score]):

        cur_server = 0 if np.sum(cur_score) % 4 in [0, 1] else 1

        if all([x == 4 for x in cur_score]):

            cur_server = 1

        if player_wins_point(serve_win_probs[cur_server]):

            cur_score[cur_server] += 1

        else:

            cur_score[1 - cur_server] += 1

    return cur_score


def play_tiebreak(serve_win_probs, min_points=7, is_ad=True):

    cur_score = np.zeros(2, dtype=np.int)

    condition = ad_win_condition if is_ad else no_ad_win_condition

    while not condition(cur_score, min_points):

        cur_server = 0 if np.sum(cur_score) % 4 in [0, 3] else 1
        cur_prob = serve_win_probs[cur_server]

        if player_wins_point(cur_prob):

            cur_score[cur_server] += 1

        else:

            cur_score[1 - cur_server] += 1

    return cur_score
