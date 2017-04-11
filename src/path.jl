export
    AllowedTimeType,
    Path,
    samplepath

"""
    AllowedTimeType

Syntactic sugar for union type of Vector{Float} and LinSpace{Float} (types
accepted for the `samplelocalpath` function).
"""
AllowedTimeType = Union{Vector{Float}, LinSpace{Float}}


"""
    Path

Type to store a path simulated via PDMP sampling. It stores the corners and the
times.
"""
type Path
    xs::Matrix{Float}  # corners (dim: nfeatures * nsteps)
    ts::Vector{Float}  # times (dim: nsteps)
    # -- implicit
    p::Int      # nfeatures
    nseg::Int   # number of segments
    Path(xs,ts) = new(xs,ts,size(xs,1), length(ts)-1)
end

"""
    Segment

Type to store the information relative to a single segment within a path in the
global BPS.
"""
immutable Segment
    ta::Float
    tb::Float
    xa::Vector{Float}
    xb::Vector{Float}
    # -- implicit
    tau::Float
    v::Vector{Float}
    Segment(ta,tb,xa,xb) = new(ta,tb,xa,xb,tb-ta,(xb-xa)/(tb-ta))
end

"""
    getsegment(p, j)

Retrieves segment j where j=1 corresponds to the first segment from the initial
time to the first corner.
"""
getsegment(p::Path, j::Int) = Segment(p.ts[j],p.ts[j+1],p.xs[:,j],p.xs[:,j+1])

"""
    samplepath(p, t)

Sample the piecewise linear trajectory defined by the corners `xs` and the
times `ts` at given time `t`.
"""
function samplepath(p::Path, t::AllowedTimeType)::Matrix{Float}
    @assert t[1] >= p.ts[1] && t[end] <= p.ts[end]
    samples = zeros(p.p,length(t))
    #
    ti  = t[1]
    j   = searchsortedlast(p.ts,ti)
    seg = getsegment(p,j)
    i   = 1
    while i <= length(t)
        ti = t[i]
        if ti <= seg.tb
            samples[:,i] = seg.xa + (ti-seg.ta) * seg.v
            # increment
            i += 1
        else
            j  += searchsortedlast(p.ts[j+1:end],ti)
            seg = getsegment(p,j)
        end
    end
    samples
end
samplepath(p::Path, t::Float) = samplepath(p,[t])[:,1]
