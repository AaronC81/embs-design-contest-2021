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

    def get_value(name)
        genotypes[self.class.instance_variable_get(:@genes_lookup)[name]]
    end

    def solution_array
        TASK_COUNT.times.map do |i|
            [i, get_value([i, :x]), get_value([i, :y])]
        end
    end

    def solution_string
        TASK_COUNT.times.map do |i|
            "#{i} #{get_value([i, :x])} #{get_value([i, :y])}"
        end.join("\n")
    end

    def fitness
        errors = count_errors(solution_array)
    end
end

pop = Darwinning::Population.new(
    organism: Allocation,
    population_size: 30,
    fitness_goal: 0,
    generations_limit: 10000
)

pop.evolve!

puts "----"
puts pop.best_member.solution_string
puts "----"
count_errors(pop.best_member.solution_string, verbose: true)
