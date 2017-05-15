const TikzPictureOrStr = Union{TikzPicture, String}

type TikzDocument <: OptionType
    elements::Vector # Plots, nodes etc
    preamble::Vector{String}

    function TikzDocument(elements::Vector, preamble::Union{String, Vector{String}})
        new(elements, vcat(DEFAULT_PREAMBLE, CUSTOM_PREAMBLE, preamble))
    end
end

function TikzDocument(; preamble = String[])
    TikzDocument([], preamble)
end

TikzDocument(element, args...) = TikzDocument([element], args...)
TikzDocument(elements::Vector; preamble = String[]) = TikzDocument(elements, preamble)

Base.push!(td::TikzDocument, v) = (push!(td.elements, v); td)

##########
# Output #
##########

function save(filename::String, td::TikzDocument; include_preamble::Bool = true,
                                                  latex_engine = latexengine(),
                                                  buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS))
    file_ending = split(basename(filename), '.')[end]
    filename_stripped = filename[1:end-4] # This is ugly, whatccha gonna do about it?
    if !(file_ending in ("tex", "svg", "pdf"))
        throw(ArgumentError("allowed file endings are .tex, .svg, .pdf"))
    end
    if file_ending == "tex"
        savetex(filename_stripped, td; include_preamble = include_preamble)
    elseif file_ending == "svg"
        savesvg(filename_stripped, td; latex_engine = latex_engine,
                                       buildflags = buildflags)
    elseif file_ending == "pdf"
        savepdf(filename_stripped, td; latex_engine = latex_engine,
                                       buildflags = buildflags)
    end
    return
end

# TeX
function savetex(filename::String, td::TikzDocument; include_preamble::Bool = true)
    open("$(filename).tex", "w") do tex
        savetex(tex, td; include_preamble = include_preamble)
    end
end

_OLD_LUALATEX = false

savetex(io::IO, td::TikzDocument; include_preamble::Bool = true) = print_tex(io, td; include_preamble = include_preamble)

function print_tex(io::IO, td::TikzDocument; include_preamble::Bool = true)
    global _OLD_LUALATEX
    if isempty(td.elements)
        warn("Tikz document is empty")
    end
    if include_preamble
        if !_OLD_LUALATEX
            println(io, "\\RequirePackage{luatex85}")
        end
        # Temp workaround for CI
        println(io, "\\documentclass{standalone}")
        _print_preamble(io)
        println(io, "\\begin{document}")
    end
    for element in td.elements
        print_tex(io, element, td)
        println(io)
    end
    if include_preamble
        println(io, "\\end{document}")
    end
end


_HAS_WARNED_SHELL_ESCAPE = false

function savepdf(path::String, td::TikzDocument; latex_engine = latexengine(),
                                                     buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS))
    global _HAS_WARNED_SHELL_ESCAPE, _OLD_LUALATEX
    run_again = false

    filename = basename(path)
    savetex(filename, td)
    latexcmd = _latex_cmd(filename, latex_engine, buildflags)
    latex_success = success(latexcmd)

    log = readstring("$filename.log")
    rm("$filename.log"; force = true)
    rm("$filename.aux"; force = true)
    rm("$filename.tex"; force = true)

    if !latex_success
        DEBUG && println("LaTeX command $latexcmd failed")
        if !_OLD_LUALATEX && contains(log, "File `luatex85.sty' not found")
            DEBUG && println("The log indicates luatex85.sty is not found, trying again without require")
            _OLD_LUALATEX = true
            run_again = true
        elseif (contains(log, "Maybe you need to enable the shell-escape feature") ||
            contains(log, "Package pgfplots Error: sorry, plot file{"))
            if !_HAS_WARNED_SHELL_ESCAPE
                warn("Detecting need of --shell-escape flag, enabling it for the rest of the session and running latex again")
                _HAS_WARNED_SHELL_ESCAPE = true
            end
            DEBUG && println("The log indicates that shell-escape is needed")
            shell_escape = "--shell-escape"
            if !(shell_escape in [DEFAULT_FLAGS; CUSTOM_FLAGS])
                DEBUG && println("Adding shell-escape and trying to save pdf again")
                # Try again with enabling shell_escape
                push!(DEFAULT_FLAGS, shell_escape)
                run_again = true
            else
                latexerrormsg(log)
                error(string("The latex command $latexcmd failed ",
                             "shell-escape feature seemed to not be ",
                             "detected even though it was passed as a flag"))
            end
        else
            latexerrormsg(log)
            error("The latex command $latexcmd failed")
        end
    end
    if run_again
        savepdf(path, td)
        return
    end
    if normpath(filename) != normpath(path)
            mv(filename * ".pdf", joinpath(path * ".pdf"); remove_destination = true)
    end
end

function savesvg(filename::String, td::TikzDocument; latex_engine = latexengine(),
                                                     buildflags = vcat(DEFAULT_FLAGS, CUSTOM_FLAGS))
    tmp = tempname()
    keep_pdf = isfile(filename * ".pdf")
    savepdf(tmp, td, latex_engine = latex_engine, buildflags = buildflags)
    # TODO Better error
    svg_cmd = `pdf2svg $tmp.pdf $filename.svg`
    svg_sucess = success(`pdf2svg $tmp.pdf $filename.svg`)
    if !svg_sucess
        error("Failed to run $svg_cmd")
    end
    if !keep_pdf
        rm("$tmp.pdf")
    end
end

Base.mimewritable(::MIME"image/svg+xml", ::TikzDocument) = true

# Below here, Copyright TikzPictures.jl (see LICENSE.md)

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

function Base.show(f::IO, ::MIME"image/svg+xml", td::TikzDocument)
    global _tikzid
    filename = tempname()
    savesvg(filename, td)
    s = readstring("$filename.svg")
    s = replace(s, "glyph", "glyph-$(_tikzid)-")
    s = replace(s, "\"clip", "\"clip-$(_tikzid)-")
    s = replace(s, "#clip", "#clip-$(_tikzid)-")
    s = replace(s, "\"image", "\"image-$(_tikzid)-")
    s = replace(s, "#image", "#image-$(_tikzid)-")
    s = replace(s, "linearGradient id=\"linear", "linearGradient id=\"linear-$(_tikzid)-")
    s = replace(s, "#linear", "#linear-$(_tikzid)-")
    s = replace(s, "image id=\"", "image style=\"image-rendering: pixelated;\" id=\"")
    _tikzid += 1
    println(f, s)
    rm("$filename.svg")
end


_is_ijulia() = isdefined(Main, :IJulia) && Main.IJulia.inited
_is_juno() = isdefined(Main, :Juno) && Main.Juno.isactive()

const _SHOWABLE = Union{Plot, AbstractVector{Plot}, AxisLike, TikzDocument, TikzPicture}

media(_SHOWABLE, Media.Plot)

function Media.render(pane::Juno.PlotPane, p::_SHOWABLE)
    f = tempname() * ".svg"
    save(f, p)
    Media.render(pane, Hiccup.div(style="background-color:#ffffff",
                       Hiccup.img(src = f)))
end

_DISPLAY_PDF = true
enable_interactive(v::Bool) = global _DISPLAY_PDF = v

function Base.show(io::IO, ::MIME"text/plain", p::_SHOWABLE)
    if isinteractive() && _DISPLAY_PDF && !_is_ijulia() && !_is_juno()
        f = tempname() .* ".pdf"
        save(f, p)
        try
            if is_linux() || is_bsd()
                run(`xdg-open $f`)
            elseif is_windows()
                run(`start $f`)
            elseif is_apple()
                run(`open $f`)
            end
        catch e
            error("Failed to show the generated pdf, run `PGFPlotsX.enable_interactive(false) to stop trying to show pdfs.`")
        end
    else
        print(io, p)
    end
end
