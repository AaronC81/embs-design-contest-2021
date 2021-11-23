# Usage: x y output

TASK_COUNT = File.read(File.join(__dir__, "data", "tasks")).split("\n").length

X_RANGE = ARGV[0].to_i.times.to_a
Y_RANGE = ARGV[1].to_i.times.to_a

File.open(ARGV[2], "w") do |f|
    TASK_COUNT.times do |i|
        f.puts "#{i} #{X_RANGE.sample} #{Y_RANGE.sample}"
    end
end
