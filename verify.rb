TASK_UTIL = File.read(File.join(__dir__, "data", "tasks")).split("\n").map { |l| l.strip.to_f }
Communication = Struct.new('Communication', :util, :sender, :receiver) do
    def to_s
        "[t#{sender} -> t#{receiver} util #{util}]"
    end
    alias inspect to_s
end
COMMUNICATIONS = File.read(File.join(__dir__, "data", "comms")).split("\n").map do |l|
    l = l.split
    Communication.new(l[1].to_f, l[2].to_i, l[3].to_i)
end

InterRouterFlow = Struct.new('InterRouterFlow', :from_x, :from_y, :to_x, :to_y) do
    def to_s
        "(#{from_x}, #{from_y}) -> (#{to_x}, #{to_y})"
    end
    alias inspect to_s
end

def count_errors(solution, verbose: false)
    if solution.is_a?(String)
        lines = solution.split("\n").map { |l| l.split.map { |i| i.strip.to_i } }
    else
        lines = solution
    end
    errors = []

    # TODO: does not consider factors

    # Find mesh X and Y dimensions
    mesh_x = lines.map { |l| l[1] }.max + 1
    mesh_y = lines.map { |l| l[2] }.max + 1
    puts "Mesh X: #{mesh_x}, Mesh Y: #{mesh_y}" if verbose

    # Construct mesh of tasks - indexed mesh[x][y]
    allocated_tasks = {} # allocated_tasks[task1] = [x, y]
    mesh = Array.new(mesh_x) { Array.new(mesh_y) { [] } } # hash[x][y] = [task1, task2, ...]
    lines.each do |line|
        mesh[line[1]][line[2]] << line[0]
        allocated_tasks[line[0]] = [line[1], line[2]]
    end

    # Check all tasks are allocated
    expected_tasks = TASK_UTIL.length.times.to_a
    if allocated_tasks.keys.sort != expected_tasks
        errors << "Not all tasks are allocated:\n    Expected: #{expected_tasks}\n    Got: #{allocated_tasks.keys.sort}"
    end

    # Check that no tile is over-utilised
    mesh_x.times do |x|
        mesh_y.times do |y|
            tasks_in_tile = mesh[x][y]
            total_util_in_tile = tasks_in_tile.map { |t| TASK_UTIL[t] }.sum

            errors << "Utilisation in tile (#{x}, #{y}) is greater than 1 (#{total_util_in_tile})" \
                if total_util_in_tile > 1
        end
    end

    # Check that no inter-router flow is over-utilised
    inter_router_flows = {} # inter_router_flows[InterRouterFlow] = [comm1, comm2, ...]
    tile_to_router_flows = {} # tile_to_router_flows[[x, y]] = [comm1, comm2]
    COMMUNICATIONS.each do |comm|
        # Where's the sender and receiver?
        sender_x, sender_y = allocated_tasks[comm.sender]
        receiver_x, receiver_y = allocated_tasks[comm.receiver]

        if [sender_x, sender_y, receiver_x, receiver_y].any?(&:nil?)
            errors << "Cannot check communication #{comm.sender} -> #{comm.receiver} because one node is unallocated"
            next
        end

        # No cost if they are the same
        next if [sender_x, sender_y] == [receiver_x, receiver_y]

        # Store tile-to-router for later
        tile_to_router_flows[[sender_x, sender_y]] ||= []
        tile_to_router_flows[[sender_x, sender_y]] << comm

        # Calculate X movement
        x_steps = if sender_x < receiver_x
            # Needs to move right to reach receiver
            (sender_x..receiver_x).to_a.each_cons(2) 
        elsif sender_x > receiver_x
            # Needs to move left to reach receiver
            (receiver_x..sender_x).to_a.reverse.each_cons(2)
        else
            []
        end
        x_steps.each do |from_x, to_x|
            ir_flow = InterRouterFlow.new(from_x, sender_y, to_x, sender_y)
            inter_router_flows[ir_flow] ||= []
            inter_router_flows[ir_flow] << comm
        end

        # Calculate Y movement
        y_steps = if sender_y < receiver_y
            # Needs to move down to reach receiver
            (sender_y..receiver_y).to_a.each_cons(2) 
        elsif sender_y > receiver_y
            # Needs to move up to reach receiver
            (receiver_y..sender_y).to_a.reverse.each_cons(2)
        else
            []
        end
        y_steps.each do |from_y, to_y|
            ir_flow = InterRouterFlow.new(receiver_x, from_y, receiver_x, to_y)
            inter_router_flows[ir_flow] ||= []
            inter_router_flows[ir_flow] << comm
        end
    end
    inter_router_flows.each do |flow, comms|
        if comms.map(&:util).sum > 1
            errors << "The flow #{flow} is over-utilised, by: #{comms}"
        end
    end

    # Check links from tiles to routers
    tile_to_router_flows.each do |(x, y), comms|
        if comms.map(&:util).sum > 1
            errors << "Tile-to-router flow for (#{x}, #{y}) is over-utilised, by: #{comms}"
        end
    end

    if verbose
        puts errors.map { |e| "ERROR: #{e} " }
        puts "------"
        puts "Total errors: #{errors.length}"
    end

    errors.length
end

if __FILE__ == $0
    errors = count_errors(File.read(ARGV[0]), verbose: true)
    exit 1 if errors > 0
end
