const __is_juno = Ref(false)

function __init__()

    @require Juno="e5e0dc1b-0480-54bc-9374-aad01c23163d" begin
        __is_juno[] = true
    end

    pushdisplay(PGFPlotsXDisplay())
    atreplinit(i -> begin
        if PlotDisplay() in Base.Multimedia.displays
            popdisplay(PGFPlotsXDisplay())
        end
        pushdisplay(PGFPlotsXDisplay())
    end)

    @require Colors="5ae59095-9a9b-59fe-a467-6f913c188581" begin
        function _rgb_for_printing(c::Colors.Colorant)
            rgb = convert(Colors.RGB{Float64}, c)
            # round colors since pgfplots cannot parse scientific notation, eg 1e-10
            round.((Colors.red(rgb), Colors.green(rgb), Colors.blue(rgb)); digits = 4)
        end

        function PGFPlotsX.print_opt(io::IO, c::Colors.Colorant)
            rgb_64 = _rgb_for_printing(c)
            print(io, "rgb,1:",
                  "red,"  , rgb_64[1], ";",
                  "green,", rgb_64[2], ";",
                  "blue," , rgb_64[3])
        end

        # For printing surface plots with explicit color, pgfplots manual 4.6.7.
        # If there are any other uses outside options that need a different format,
        # we should introduce a wrapper type.
        function PGFPlotsX.print_tex(io::IO, c::Colors.Colorant)
            rgb_64 = _rgb_for_printing(c)
            print(io, "rgb=", rgb_64[1], ",", rgb_64[2], ",", rgb_64[3])
        end

        function PGFPlotsX.print_tex(io::IO, c::Tuple{String, Colors.Colorant}, ::Any)
            name, color = c
            rgb_64 = _rgb_for_printing(color)
            print(io, "\\definecolor{$name}{rgb}{$(rgb_64[1]), $(rgb_64[2]), $(rgb_64[3])}")
        end

        function PGFPlotsX.print_tex(io::IO,
                                     c::Tuple{String, Vector{<:Colors.Colorant}},
                                     ::Any)
            name, colors = c
            println(io, "\\pgfplotsset{ colormap={$name}{")
            for col in colors
                rgb_64 = _rgb_for_printing(col)
                println(io, "rgb=(", join(rgb_64, ","), ")")
            end
            println(io, "}}")
        end
    end

    @require Contour="d38c429a-6771-53c6-b99e-75d170b6e991" begin
        function PGFPlotsX.TableData(c::Contour.ContourCollection; kwargs...)
            colx = Any[]
            coly = Any[]
            colz = Any[]
            ns = Int[]
            for cl in Contour.levels(c)
                lvl = Contour.level(cl) # the z-value of this contour level
                for line in Contour.lines(cl)
                    xs, ys = Contour.coordinates(line) # coordinates of this line segment
                    n = length(xs)
                    append!(colx, xs)
                    append!(coly, ys)
                    append!(colz, fill(lvl, n))
                    push!(ns, n)
                end
            end
            TableData(hcat(colx, coly, colz); colnames=["x", "y", "z"], scanlines=cumsum(ns), kwargs...)
        end
    end

    @require StatsBase="2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91" begin
        function PGFPlotsX.TableData(h::StatsBase.Histogram{T, 1};
                                     kwargs...) where T
            PGFPlotsX.TableData(hcat(h.edges[1], vcat(h.weights, 0)); kwargs...)
        end

        function PGFPlotsX.TableData(histogram::StatsBase.Histogram{T, 2};
                                     kwargs...) where T
            PGFPlotsX.TableData(StatsBase.midpoints(histogram.edges[1]),
                                StatsBase.midpoints(histogram.edges[2]),
                                histogram.weights; kwargs...)
        end

        function PGFPlotsX.TableData(e::StatsBase.ECDF; n = 100, kwargs...)
            x = range(extrema(e)...; length = n)
            PGFPlotsX.TableData(hcat(x, map(e, x)); kwargs...)
        end

        function PGFPlotsX.Coordinates(histogram::StatsBase.Histogram{T, 2}) where T
            PGFPlotsX.Coordinates(StatsBase.midpoints(histogram.edges[1]),
                                  StatsBase.midpoints(histogram.edges[2]),
                                  histogram.weights)
        end
    end

    @require Measurements="eff96d63-e80a-5855-80a2-b1b0885c5ab7" begin
        function PGFPlotsX.Coordinates(x::AbstractVector{T}, y::AbstractVector;
                                    kwargs...) where T <: Measurements.Measurement{<:Real}
            Coordinates(Measurements.value.(x), y;
                xerror = Measurements.uncertainty.(x), kwargs...)
        end

        function PGFPlotsX.Coordinates(x::AbstractVector, y::AbstractVector{T};
                                    kwargs...) where T <: Measurements.Measurement{<:Real}
            Coordinates(x, Measurements.value.(y);
                yerror = Measurements.uncertainty.(y), kwargs...)
        end

        function PGFPlotsX.Coordinates(x::AbstractVector{T}, y::AbstractVector{T};
                                    kwargs...) where T <: Measurements.Measurement{<:Real}
            Coordinates(Measurements.value.(x), Measurements.value.(y);
                xerror = Measurements.uncertainty.(x),
                yerror = Measurements.uncertainty.(y), kwargs...)
        end
    end

    @require PlotUtils="995b91a9-d308-5afd-9ec6-746e21dbc043" begin

    function PGFPlotsX.print_tex(io::IO, c::Symbol) # TODO is this dispatch too wide?  Could we create a ColorGradient type?
        PGFPlotsX.print_tex(io, (string(c), PlotUtils.cvec(c)))
    end

    end
end
