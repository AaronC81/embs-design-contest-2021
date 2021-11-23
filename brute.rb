counter = 0

loop do
    `ruby random_sol.rb #{ARGV[0]} #{ARGV[1]} brute.sol`
    `ruby verify.rb brute.sol`
    break if $?.success?

    counter += 1
    puts "Tried #{counter} solutions..." if counter % 100 == 0
end
