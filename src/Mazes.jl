module Mazes
using SimpleGraphs, SimplePartitions, SimpleDrawing, Plots

_vtx = Tuple{Int,Int}
_edge = Tuple{_vtx,_vtx}


import SimpleDrawing: draw
import Base: show, size
export Maze, draw_ans, draw, amaze


"""
`M = Maze(r,c)` creates an `r`-by-`c` maze. To see the maze,
use `draw(M)`. The maze is meant to be solved from the upper left
to the lower right. This is indicated by stars at those locations.
To draw the maze without those stars, use `draw(M,false)`.

To draw the solution to the maze, use `draw_ans(M)`. The solutions is
always drawn without stars.
"""
struct Maze
    r::Int  # number of rows
    c::Int  # number of cols
    T::SimpleGraph{_vtx}  # the tree for this maze
    function Maze(nr::Int, nc::Int)
        G = _gen_tree(nr, nc)
        new(nr, nc, G)
    end
end

Maze(n::Int) = Maze(n, n)


function show(io::IO, M::Maze)
    print(io, "Maze($(M.r),$(M.c))")
end

"""
`size(M::Maze)` returns a tuple `(r,c)` where `r` is the number of
rows and `c` is the number of columns in the maze.
"""
size(M::Maze) = (M.r, M.c)

function _gen_tree(nr, nc)
    @assert nr >= 2 && nc >= 2 "Inputs must both be at least 2"
    G = Grid(nr, nc)

    EE = elist(G)  # all possible edges
    # assign random weights to edges
    wt = Dict{_edge,Float64}()
    for e in EE
        wt[e] = rand()
    end

    # the upper left and lower right squares should be leaves
    # these weights should enforce that

    e1 = ((1, 1), (1, 2))
    e2 = ((1, 1), (2, 1))
    if rand() > 0.5
        wt[e1] = 0
        wt[e2] = 1
    else
        wt[e1] = 1
        wt[e2] = 0
    end

    e1 = (nr - 1, nc), (nr, nc)
    e2 = (nr, nc - 1), (nr, nc)
    if rand() > 0.5
        wt[e1] = 0
        wt[e2] = 1
    else
        wt[e1] = 1
        wt[e2] = 0
    end

    wt_list = [wt[e] for e in EE]
    p = sortperm(wt_list)
    E_list = [EE[j] for j in p] # EE sorted by weight

    # copy vertices from G
    T = SimpleGraph{_vtx}()
    for v in G.V
        add!(T, v)
    end
    P = Partition(G.V)

    for e in E_list
        a = e[1]
        b = e[2]
        if !in_same_part(P, a, b)
            add!(T, a, b)
            merge_parts!(P, a, b)
        end
    end

    d = Dict{_vtx,Array{Int,1}}()
    for v in T.V
        x = v[1]
        y = v[2]
        d[v] = [y, -x]
    end
    embed(T, d)
    return T
end


function _puzzle_draw(M::Maze)
    # get the tree's embedding
    xy = M.T.cache[:xy]

    newdraw()
    # draw(M.T)  # DEBUG #

    # draw outside rectangle
    ul = (0.5, -0.5)
    ur = (M.c + 0.5, -0.5)
    ll = (0.5, -M.r - 0.5)
    lr = (M.c + 0.5, -M.r - 0.5)

    draw_segment(ul..., ur..., color = :black)
    draw_segment(ul..., ll..., color = :black)
    draw_segment(ur..., lr..., color = :black)
    draw_segment(ll..., lr..., color = :black)

    G = Grid(M.r, M.c)

    non_edge_list = [e for e in G.E if !has(M.T, e[1], e[2])]

    for e in non_edge_list
        a = e[1]
        b = e[2]
        mid = 0.5 * (xy[a] + xy[b])

        if a[1] == b[1]  # vertical segment
            x = mid[1]
            y1 = mid[2] - 0.5
            y2 = mid[2] + 0.5
            draw_segment(x, y1, x, y2, color = :black)
        else
            x1 = mid[1] - 0.5
            x2 = mid[1] + 0.5
            y = mid[2]
            draw_segment(x1, y, x2, y, color = :black)
        end

    end
end

"""
`draw(M::Maze)` draws the maze `M` on the screen. Circles mark the start
(upper left) and end (lower right). The size is printed above the maze.

Full syntax: `draw(M::Maze, markers::Bool=true, title::Bool=true)`
"""
function draw(M::Maze, markers::Bool=true, title::Bool=true)
    _puzzle_draw(M)

    if markers
        r = 0.125
        draw_circle(1, -1, r, color = :black)
        draw_circle(M.c, -M.r, r, color = :black)
    end

    if title
        plot!(title = "$(M.r)-by-$(M.c)")
    end

    finish()
end

function _ans_draw(M::Maze, s::_vtx, t::_vtx)
    xy = M.T.cache[:xy]
    @assert has(M.T, s) "$s not a square in this maze"
    @assert has(M.T, t) "$t not a square in this maze"
    if s == t
        @warn "Two locations are the same, no path will be drawn"
    end
    P = find_path(M.T, s, t)
    n = length(P)
    for i = 1:n-1
        a = P[i]
        xa, ya = xy[a]
        b = P[i+1]
        xb, yb = xy[b]
        draw_segment(xa, ya, xb, yb, color = :red, style = :dot)
    end
end

"""
`draw_ans(M::Maze)` draws the maze `M` and the solution (as a dotted red line)
from the start (upper left) to the end (lower right).

To draw a different path (solution) use `draw(M,s,t)` where `s` and `t` are
integer 2-tuples. Note that squares in the maze are indexed like a matrix,
so `(2,3)` refers to the cell in row 2, column 3.
"""
function draw_ans(M::Maze, s::_vtx, t::_vtx)
    _puzzle_draw(M)
    _ans_draw(M, s, t)
    finish()
end

draw_ans(M::Maze) = draw_ans(M, (1, 1), size(M))

"""
`amaze(r,c)` creates and draws a maze.
"""
function amaze(r::Int, c::Int)
    M = Maze(r, c)
    draw(M)
end



end # end of module
