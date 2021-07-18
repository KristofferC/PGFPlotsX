"""
    TikzDocument(elements...; use_default_preamble = true, preamble = [])

Corresponds to a LaTeX document, usually wrapping `TikzPicture`s.

`use_default_preamble` determines whether a preamble is added from the global
variables (see [`CUSTOM_PREAMBLE`](@ref) and [`CUSTOM_PREAMBLE_PATH`](@ref)).

`preamble` is appended after the default one (if any).

`push!` can be used to append elements after construction, and similarly
`push_preamble!` for the preamble.
"""
struct TikzDocument
    elements::Vector{Any}
    "Flag for adding the default preamble before `preamble`."
    use_default_preamble::Bool
    "Add to the preamble."
    preamble::Vector{Any}
    function TikzDocument(elements...; use_default_preamble = true, preamble = [])
        new(collect(Any, elements), use_default_preamble, preamble)
    end
end

Base.push!(t::TikzDocument, args...; kwargs...) = (push!(t.elements, args...; kwargs...); t)
Base.append!(t::TikzDocument, args...; kwargs...) = (append!(t.elements, args...; kwargs...); t)

"""
    $SIGNATURES

Works like `push!`, but places `items` in the preamble.
"""
push_preamble!(td::TikzDocument, items...) = (push!(td.preamble, items...); td)

##########
# Output #
##########

"""
Extensions that make [`save`](@ref) choose a standalone `tikz` format.

The saved file has no preamble, just a `tikzpicture` environment. These
extensions should be recognized by `\\includegraphics` when the
[tikzscale](https://www.ctan.org/pkg/tikzscale) LaTeX package is used.
"""
const STANDALONE_TIKZ_FILEEXTS = [".tikz", ".TIKZ", ".TikZ", ".pgf", ".PGF"]

struct MissingExternalProgramError <: Exception
    str::AbstractString
end
MissingExternalProgramError(strs...) = MissingExternalProgramError(join(strs))

function Base.showerror(io::IO, e::MissingExternalProgramError)
    print(io, e.str)
end

"""
    $SIGNATURES

Save the argument (either [`TikzDocument`](@ref), or some other type which is
wrapped in one automatically, eg [`TikzPicture`](@ref), [`Axis`](@ref), or
[`Plot`](@ref)) to `filename`, guessing the format from the file extension.
Keywords specify options, some specific to some output formats.

`pgfsave` is an alias which is exported.
"""
function save(filename::AbstractString, td::TikzDocument;
              include_preamble::Bool = true,
              latex_engine = latexengine(),
              buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS),
              dpi = 150,
              showing_ide = false)
    filebase, fileext = splitext(filename)
    if showing_ide
        td = deepcopy(td)
        pushfirst!(td.preamble, "\\usepackage{pagecolor}")
        pushfirst!(td.elements, "\\pagecolor{white}")
    end
    if fileext == ".tex"
        savetex(filename, td; include_preamble = include_preamble)
    elseif fileext ∈ STANDALONE_TIKZ_FILEEXTS
        savetex(filename, td; include_preamble = false)
    elseif fileext == ".svg"
        savesvg(filename, td; latex_engine = latex_engine, buildflags = buildflags)
    elseif fileext == ".pdf"
        savepdf(filename, td; latex_engine = latex_engine, buildflags = buildflags)
    elseif fileext == ".png"
        savepng(filename, td;
                latex_engine = latex_engine, buildflags = buildflags, dpi = dpi)
    else
        allowed_file_endings = vcat(["tex", "pdf", "png", "svg"],
                                    lstrip.(STANDALONE_TIKZ_FILEEXTS, '.'))
        throw(ArgumentError("allowed file endings are $(join(allowed_file_endings, ", "))."))
    end
    return
end

const pgfsave = save

# TeX
function savetex(filename::AbstractString, td::TikzDocument;
                 include_preamble::Bool = true)
    open(filename, "w") do io
        savetex(io, td; include_preamble = include_preamble)
    end
end

_OLD_LUALATEX = false

"""
List of class options used in the preamble (default `["tikz"]`).

By setting
`PGFPlotsX.CLASS_OPTIONS[1] = "varwidth"; push!(PGFPlotsX.CLASS_OPTIONS, "crop=false")`
the preamble will contain `documentclass[varwidth,crop=false]{standalone}`.

See https://www.ctan.org/pkg/standalone for a list of options.
"""
CLASS_OPTIONS = ["tikz"]

savetex(io::IO, td::TikzDocument; include_preamble::Bool = true) =
    print_tex(io, td; include_preamble = include_preamble)

function print_tex(io::IO, td::TikzDocument; include_preamble::Bool = true)
    global _OLD_LUALATEX
    @unpack elements, use_default_preamble, preamble = td
    if isempty(td.elements)
        @warn("Tikz document is empty")
    end
    if include_preamble
        if !_OLD_LUALATEX
            println(io, "\\RequirePackage{luatex85}")
        end
        # Temp workaround for CI
        println(io, "\\documentclass[$(join(CLASS_OPTIONS, ','))]{standalone}")
        if use_default_preamble
            preamble = vcat(_default_preamble(), preamble)
        end
        for preamble_line in preamble
            print_tex(io, preamble_line, td)
        end
        println(io, "\\begin{document}")
    else
        print_tex(io,"% Recommended preamble:")
        for preamble_line in preamble
            print_tex(io,replace(preamble_line,r"^"m => s"% "),td)
        end
    end
    for element in td.elements
        print_tex(io, element, td)
    end
    if include_preamble
        println(io, "\\end{document}")
    end
end

_HAS_WARNED_SHELL_ESCAPE = false

function savepdf(filename::AbstractString, td::TikzDocument;
                 latex_engine = latexengine(),
                 buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS),
                 run_count = 0, tmp = tempname())
    global _HAS_WARNED_SHELL_ESCAPE, _OLD_LUALATEX
    run_again = false

    tmp_tex = tmp * ".tex"
    tmp_pdf = tmp * ".pdf"
    savetex(tmp_tex, td)
    latex_success, log, latexcmd = run_latex_once(tmp_tex,
                                                  latex_engine, buildflags)

    if !latex_success
        @debug "LaTeX command $latexcmd failed"
        if !_OLD_LUALATEX && occursin("File `luatex85.sty' not found", log)
            @debug "The log indicates luatex85.sty is not found, trying again without require"
            _OLD_LUALATEX = true
            run_again = true
        elseif (occursin("Maybe you need to enable the shell-escape feature", log) ||
                occursin("Package pgfplots Error: sorry, plot file{", log))
            if !_HAS_WARNED_SHELL_ESCAPE
                @warn("Detecting need of --shell-escape flag, enabling it for the rest of the session and running latex again")
                _HAS_WARNED_SHELL_ESCAPE = true
            end
            @debug "The log indicates that shell-escape is needed"
            shell_escape = "--shell-escape"
            if !(shell_escape in [DEFAULT_FLAGS; CUSTOM_FLAGS])
                @debug "Adding shell-escape and trying to save pdf again"
                # Try again with enabling shell_escape
                push!(DEFAULT_FLAGS, shell_escape)
                push!(buildflags, shell_escape)
                run_again = true
            else
                latexerrormsg(log)
                rm_tmpfiles(tmp_tex)
                error(string("The latex command $latexcmd failed ",
                             "shell-escape feature seemed to not be ",
                             "detected even though it was passed as a flag"))
            end
        else
            latexerrormsg(log)
            rm_tmpfiles(tmp_tex)
            error("The latex command $latexcmd failed")
        end
    end
    run_again = run_again || occursin("LaTeX Warning: Label(s) may have changed", log)
    if run_again && run_count == 4
        rm_tmpfiles(tmp_tex)
        error("ran latex 5 times without converging, log is:\n$log")
    end
    if run_again
        savepdf(filename, td; latex_engine=latex_engine, buildflags=buildflags,
                run_count=run_count+1, tmp = tmp)
        return
    end
    rm_tmpfiles(tmp_tex)
    mv(tmp_pdf, filename; force = true)
end

const _SHOWABLE = Union{Plot, AbstractVector{Plot}, AxisLike, TikzDocument, TikzPicture}

function Base.show(io::IO, ::MIME"application/pdf", p::_SHOWABLE)
    filename = tempname() * ".pdf"
    save(filename, p; showing_ide=_is_ide())
    write(io, read(filename))
    rm(filename; force = true)
end

# Copyright TikzPictures.jl (see LICENSE.md)
function latexerrormsg(s)
    beginError = false
    for l in split(s, '\n')
        if beginError
            if !isempty(l) && l[1] == '?'
                return
            else
                println(l)
            end
        else
            if !isempty(l) && l[1] == '!'
                println(l)
                beginError = true
            end
        end
    end
end

global _tikzid = round(UInt64, time() * 1e6)

# The purpose of this is to not have IJulia call latex twice every time
# we show a figure (https://github.com/JuliaLang/IJulia.jl/issues/574)
# As a workaround, We therefore maintain a cache which should work in most
# cases, The cache is the hash of the tex output and a copy of the pdf when
# the svg is showed. The PNG shower looks for the existence of these and re-uses
# the pdf if the hash is the same
const Ijulia_cache = Any[nothing, nothing]
global showing_Ijulia = false

"""
$SIGNATURES

Save `td` in `filename` using the SVG format.

Generates an interim PDF which is deleted; use `keep_pdf = true` to copy it to
`filename` with the extension (if any) replaced by `".pdf"`. This overwrites
an existing PDF file with the same name.
"""
function savesvg(filename::AbstractString, td::TikzDocument;
                 latex_engine = latexengine(),
                 buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS),
                 keep_pdf = false)
    tmp_pdf = tempname() * ".pdf"
    savepdf(tmp_pdf, td, latex_engine = latex_engine, buildflags = buildflags)
    if _is_ijulia() && showing_Ijulia
        tmp_ijulia_pdf = tempname() * ".pdf"
        hsh = hash(sprint(print_tex, td))
        cp(tmp_pdf, tmp_ijulia_pdf)
        Ijulia_cache[[1,2]] = [hsh, tmp_ijulia_pdf]
    end
    convert_pdf_to_svg(tmp_pdf, filename)
    if keep_pdf
        mv(tmp_pdf, _replace_fileext(filename, ".pdf"); force = true)
    else
        rm(tmp_pdf)
    end
end

Base.showable(::MIME"image/svg+xml", td::_SHOWABLE) = svg_engine() !== NO_SVG_ENGINE

# Copyright TikzPictures.jl (see LICENSE.md)
function Base.show(f::IO, ::MIME"image/svg+xml", td::_SHOWABLE)
    global _tikzid
    filename = tempname() * ".svg"
    global showing_Ijulia = true
    try save(filename, td; showing_ide=_is_ide())
    finally
        global showing_Ijulia = false
    end
    s = read(filename, String)
    s = replace(s, "glyph" => "glyph-$(_tikzid)-")
    s = replace(s, "\"clip" => "\"clip-$(_tikzid)-")
    s = replace(s, "#clip" => "#clip-$(_tikzid)-")
    s = replace(s, "\"image" => "\"image-$(_tikzid)-")
    s = replace(s, "#image" => "#image-$(_tikzid)-")
    s = replace(s, "linearGradient id=\"linear" => "linearGradient id=\"linear-$(_tikzid)-")
    s = replace(s, "#linear" => "#linear-$(_tikzid)-")
    s = replace(s, "image id=\"" => "image style=\"image-rendering: pixelated;\" id=\"")
    _tikzid += 1
    println(f, s)
    rm(filename; force = true)
end

function savepng(filename::AbstractString, td::TikzDocument;
                 latex_engine = latexengine(),
                 buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS),
                 dpi::Int = 150)
    found_ijulia_cache_matching = false
    local tmp
    if _is_ijulia() && showing_Ijulia && Ijulia_cache[1] != nothing
        hsh = hash(sprint(print_tex, td))
        if Ijulia_cache[1] == hsh
            tmp = Ijulia_cache[2]
            found_ijulia_cache_matching = true
        end
        fill!(Ijulia_cache, nothing)
    end
    if !found_ijulia_cache_matching
        tmp = tempname() * ".pdf"
        savepdf(tmp, td, latex_engine = latex_engine, buildflags = buildflags)
    end
    filebase = splitext(filename)[1]
    convert_pdf_to_png(tmp, filebase; dpi=dpi)
    found_ijulia_cache_matching && rm(tmp; force=true)
end

Base.showable(::MIME"image/png", ::_SHOWABLE) = png_engine() !== NO_PNG_ENGINE
function Base.show(io::IO, ::MIME"image/png", p::_SHOWABLE)
    filename = tempname() * ".png"
    global showing_Ijulia = true
    try save(filename, p; showing_ide=_is_ide())
    finally
        global showing_Ijulia = false
    end
    write(io, read(filename))
    rm(filename; force = true)
end
_DISPLAY_PDF = true
enable_interactive(v::Bool) = global _DISPLAY_PDF = v
_is_ijulia() = isdefined(Main, :IJulia) && Main.IJulia.inited
_is_vscode() = isdefined(Main, :_vscodeserver)
_is_juno()   = __is_juno[]
_is_ide()    = _is_ijulia() || _is_vscode() || _is_juno()

function Base.display(d::PGFPlotsXDisplay, p::_SHOWABLE)
    if _DISPLAY_PDF
        filename = tempname() .* ".pdf"
        save(filename, p)
        try
            DefaultApplication.open(filename)
        catch e
            error("Failed to show the generated pdf, run `PGFPlotsX.enable_interactive(false)` to stop trying to show pdfs.\n", "Error: ", sprint(Base.showerror, e))
        end
    else
        throw(MethodError(display, (d, p)))
    end
end
