# Usage: x y output

require 'bundler/inline'
require_relative 'verify'

gemfile do
    gem 'darwinning'
end

TASK_COUNT = TASK_UTIL.length

# Darwinning uses an inclusive range end, for some reason! Offset with a -1
X_RANGE = 0..(ARGV[0].to_i - 1)
Y_RANGE = 0..(ARGV[1].to_i - 1)

class Allocation < Darwinning::Organism
    @name = "Allocation"
    @genes_lookup = {}
    @genes = TASK_COUNT.times.flat_map do |i|
        # Construct gene for both X and Y
        [
            @genes_lookup[[i, :x]] = Darwinning::Gene.new(name: "task#{i}_x", value_range: X_RANGE),
            @genes_lookup[[i, :y]] = Darwinning::Gene.new(name: "task#{i}_y", value_range: Y_RANGE),
        ]
    end

    # Gets the value of a gene, given its name e.g. `task0_x`.
    def get_value(name)
        genotypes[self.class.instance_variable_get(:@genes_lookup)[name]]
    end

    # Returns the set of genes in this organism, converted to a solution array suitable for passing
    # to `count_errors`.
    def solution_array
        TASK_COUNT.times.map do |i|
            [i, get_value([i, :x]), get_value([i, :y])]
        end
    end

    # Returns the set of genes in this organism, converted to a solution string suitable for passing
    # to `count_errors`.
    def solution_string
        TASK_COUNT.times.map do |i|
            "#{i} #{get_value([i, :x])} #{get_value([i, :y])}"
        end.join("\n")
    end

    # Returns the fitness of the solution, which is simply the number of errors it contains.
    def fitness
        errors = count_errors(solution_array)
    end
end

# Construct population and evolve it until we find a solution with `fitness` == 0, i.e. one with no
# errors
pop = Darwinning::Population.new(
    organism: Allocation,
    population_size: 15,
    fitness_goal: 0,
    generations_limit: 1000000
)

pop.evolve!

# Print solution and error count, which should be 0, unless we somehow iterate through 1000000
# generations without finding one!
puts "----"
puts pop.best_member.solution_string
puts "----"
count_errors(pop.best_member.solution_string, verbose: true)
