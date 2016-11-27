# Tennis formats
Simulation for various tennis formats, written in cython + python.

## How to run

Run the `simulate.py` script to simulate matches. It will print the results of the runs to stdout in csv format.

`python simulate.py --help`

will show a help page which should tell you the arguments required.

To redirect the output to a csv file, use standard redirection: `> results.csv`. E.g.:

`python simulate.py --match-format 'fast_four_singles' --bonus 1.2 --malus 0.1 --num-trials 1000 > results.csv`
