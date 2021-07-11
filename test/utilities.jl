# utilities for testing

"Invoke print_tex with the given arguments, collect the results in a string."
repr_tex(args...) = print_tex(String, args...)
function repr_tex_compact(args...)
    io = IOBuffer()
    print_tex(IOContext(io, :compact => true), args...)
    String(take!(io))
end

"""
Trim lines, merge whitespace to a single space, merge multiple empty lines into
one, merge beginning and ending newlines.

Useful for unit testing printed representations.
"""
function squash_whitespace(str::AbstractString)
    lines = split(str, '\n')
    squashed_lines = map(line -> replace(strip(line), r" +" => " "), lines)
    strip(replace(join(squashed_lines, "\n"), r"\n{2,}" => "\n\n"), '\n')
end

@test squash_whitespace("\n\n  a  line  \nsome   other line\n\n\ndone\n") ==
    "a line\nsome other line\n\ndone"

"Squashed result of `print_tex` with given arguments."
squashed_repr_tex(args...) = squash_whitespace(repr_tex(args...))

"A simple comparison of fields for unit tests."
≅(x, y) = x == y

function ≅(x::T, y::T) where T <: Union{PGFPlotsX.Coordinate, Coordinates,
                                        Table, TableData, Plot, Options}
    for f in fieldnames(T)
        getfield(x, f) ≅ getfield(y, f) || return false
    end
    true
end
