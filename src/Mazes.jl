module Mazes
using SimpleGraphs, SimplePartitions, SimpleDrawing

_vtx = Tuple{Int,Int}
_edge = Tuple{_vtx,_vtx}


import SimpleDrawing: draw
import Base: show
export Maze

struct Maze
    r::Int  # number of rows
    c::Int  # number of cols
    T::SimpleGraph{_vtx}  # the tree for this maze
    function Maze(nr::Int, nc::Int)
        G = _gen_tree(nr,nc)
        new(nr,nc,G)
    end
end



function show(io::IO, M::Maze)
  print(io, "Maze($(M.r), $(M.c))")
end

function _gen_tree(nr,nc)
    @assert nr>=2 && nc>=2 "Inputs must both be at least 2"
    G = Grid(nr,nc)

    EE = elist(G)  # all possible edges
    # assign random weights to edges
    wt = Dict{_edge, Float64}()
    for e in EE
        wt[e] = rand()
    end

    # the upper left and lower right squares should be leaves
    # these weights should enforce that

    e1 = ((1,1),(1,2))
    e2 = ((1,1),(2,1))
    if rand() > 0.5
        wt[e1] = 0
        wt[e2] = 1
    else
        wt[e1] = 1
        wt[e2] = 0
    end

    e1 = (nr-1,nc),(nr,nc)
    e2 = (nr,nc-1),(nr,nc)
    if rand() > 0.5
        wt[e1] = 0
        wt[e2] = 1
    else
        wt[e1] = 1
        wt[e2] = 0
    end

    wt_list = [ wt[e] for e in EE ]
    p = sortperm(wt_list)
    E_list = [ EE[j] for j in p ] # EE sorted by weight

    # copy vertices from G
    T = SimpleGraph{_vtx}()
    for v in G.V
        add!(T,v)
    end
    P = Partition(G.V)

    for e in E_list
        a = e[1]
        b = e[2]
        if !in_same_part(P,a,b)
            add!(T,a,b)
            merge_parts!(P,a,b)
        end
    end

    # create an embedding (for debugging)
    d = Dict{_vtx,Array{Int,1}}()
    for v in T.V
        x = v[1]
        y = v[2]
        d[v] = [x,y]
    end
    embed(T,d)


    return T
end



end # end of module
