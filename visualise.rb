require_relative 'verify'

# Get solution data
mesh, inter_router_flows, tile_to_router_flows, router_to_tile_flows = *count_errors(
    File.read(ARGV[0]),
    return_data: true
)

# Initialise GraphViz dot file
f = File.open("visualise.dot", "w")

f.puts "digraph {"
f.puts "   node [style=filled]"

mesh_x = mesh.length
mesh_y = mesh[0].length

SPACING = 3

# Generate nodes
mesh_x.times do |x|
    mesh_y.times do |y|
        util = mesh[x][y].map { |t| TASK_UTIL[t] }.sum
        label = mesh[x][y].join(",") + "\nUtil: #{util.round(3)}"

        f.puts "tile_x#{x}y#{y} [label=\"#{label}\" fillcolor=\"#fcba03\" pos=\"#{x * SPACING},#{y * -SPACING}!\"]"
        f.puts "router_x#{x}y#{y} [fillcolor=\"#1f77b4\" pos=\"#{x * SPACING - 1},#{y * -SPACING + 1}!\"]"

        f.puts "tile_x#{x}y#{y} -> router_x#{x}y#{y} [label=\"#{tile_to_router_flows[[x, y]].map(&:util).sum.round(3)}\"]"
        f.puts "router_x#{x}y#{y} -> tile_x#{x}y#{y} [label=\"#{router_to_tile_flows[[x, y]].map(&:util).sum.round(3)}\"]"
    end
end

# Generate links between routers 
mesh_x.times.to_a.each_cons(2) do |xa, xb|
    mesh_y.times do |y|
        f.puts "router_x#{xa}y#{y} -> router_x#{xb}y#{y} [label=\"#{inter_router_flows[InterRouterFlow.new(xa, y, xb, y)].map(&:util).sum.round(3)}\"]"
        f.puts "router_x#{xb}y#{y} -> router_x#{xa}y#{y} [label=\"#{inter_router_flows[InterRouterFlow.new(xb, y, xa, y)].map(&:util).sum.round(3)}\"]"
    end
end
mesh_y.times.to_a.each_cons(2) do |ya, yb|
    mesh_x.times do |x|
        f.puts "router_x#{x}y#{ya} -> router_x#{x}y#{yb} [label=\"#{inter_router_flows[InterRouterFlow.new(x, ya, x, yb)].map(&:util).sum.round(3)}\"]"
        f.puts "router_x#{x}y#{yb} -> router_x#{x}y#{ya} [label=\"#{inter_router_flows[InterRouterFlow.new(x, yb, x, ya)].map(&:util).sum.round(3)}\"]"
    end
end

# Finish file
f.puts "}"
f.close

# Rendering instructions
puts "Now run:"
puts "  dot -Tpng -n -Kfdp visualise.dot > visualise.png"
