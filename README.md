# EMBS Design Contest 2021

My solution for the EMBS Design Contest 2021!

All of the solution-finding algorithms must take a fixed size to search for, and also does not 
support changing factors.

The files are:

- `verify.rb <path>` checks that the solution file at `path` is valid. It can also be imported as
  a library to provide the `count_errors` method.

- `random_sol.rb x y` generates a random solution of size `x` by `y`, *which may not be valid*.

- `brute.rb x y` generates random solutions of size `x` by `y` until one is valid.

- `genetic.rb x y` uses the Darwinning genetic algorithm library to find solutions of size `x` by
  `y`. (Before running this, run `gem install darwinning`.)

The `data` directory contains the problem data, separated by spaces.

The `solutions` directory contains a variety of solutions. I've kept ones which I later found to be
invalid due to oversights in `verify.rb` - but the ones in `solutions/valid` are (hopefully!) all
valid solutions, using 1 for both factors.
