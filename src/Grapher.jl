module Grapher

using Reexport

using PGFPlotsX
using PGFPlotsX: Options
export @pgf, savegraph

@reexport using LaTeXStrings
using MappedArrays
using CSV

function __init__()
    if PGFPlotsX.latexengine() == PGFPlotsX.LUALATEX
        push!(PGFPlotsX.CUSTOM_PREAMBLE, "\\usepackage{unicode-math}")
        push!(PGFPlotsX.CUSTOM_PREAMBLE, "\\setmainfont{STIX Two Text}")
        push!(PGFPlotsX.CUSTOM_PREAMBLE, "\\setmathfont{STIX Two Math}")
    end
    push!(PGFPlotsX.CUSTOM_PREAMBLE, "\\usepackage[group-separator={,}]{siunitx}")
end

export
    plot,
    plot!,
    scatter,
    xbar_stacked,
    ybar_stacked,
    plot_fillbetween

const axis_attributes = Dict(
    :xlabel => "xlabel",
    :ylabel => "ylabel",
    :zlabel => "zlabel",
    :xmin => "xmin", :xmax => "xmax",
    :ymin => "ymin", :ymax => "ymax",
    :zmin => "zmin", :zmax => "zmax",
    :xlims => "xlims",
    :ylims => "ylims",
    :zlims => "zlims",
    :xdir => "x dir",
    :ydir => "y dir",
    :zdir => "z dir",
    :xaxis => "xmode",
    :yaxis => "ymode",
    :zaxis => "zmode",
    :enlarge_x_limits => "enlarge x limits",
    :enlarge_y_limits => "enlarge y limits",
    :enlarge_z_limits => "enlarge z limits",
    :enlargelimits => "enlargelimits",
    :xtick => "xtick",
    :ytick => "ytick",
    :ztick => "ztick",
    :xtick_precision => "xtick precision",
    :ytick_precision => "ytick precision",
    :ztick_precision => "ztick precision",
    :logtick_fixed => "logtick fixed",
    :legend_pos => "legend pos",
    :legend_columns => "legend columns",
    :legend_anchor => "legend anchor",
    :minorticks => "minor tick num",
    :width => "width",
    :height => "height",
    :size => "size",
    :cycle_list_name => "cycle list name",
    :bar_width => "bar width",
    :black => "black",
    # on/off options
    :grid => "grid",
)
const plot_attributes = Dict(
    :mark   => "mark",
    :marker => "mark",
    :mark_repeat => "mark repeat",
    :marker_repeat => "mark repeat",
    :mark_size => "mark size",
    :marker_size => "mark size",
    :color => "color",
    :fill => "fill",
    :opacity => "opacity",
    :line_width => "line width",
    :line_style => "line style",
    :fill_opacity => "fill opacity",
    :xmap => "xmap",
    :ymap => "ymap",
    :zmap => "zmap",
    :black => "black",
    # on/off options
    :smooth => "smooth",
    :only_marks   => "only marks",
    :only_markers => "only marks",
    :no_marks   => "no marks",
    :no_markers => "no marks",
    :surf => "surf",
    :mesh => "mesh",
    :scatter => "scatter",
)
const mark_attributes = Dict(
    :marker_fill => "fill",
    :marker_scale => "scale",
)

default_axis_options() =
    @pgf{
        legend_cell_align = "left",
        scale_only_axis,
        label_style = {font = raw"\footnotesize"},
        tick_label_style = {font = raw"\footnotesize"},
        legend_style = {font = raw"\footnotesize"},
        # remove yellow from "color list". Other usuful lists are, for example, "linestyles", "linestyles*".
        cycle_list = {red,blue,teal,orange,violet,cyan,green!70!black,magenta,gray,black,brown},
        minor_tick_num = 1,
    }
default_plot_options() = @pgf{semithick, mark_options = default_mark_options()}
default_mark_options() = @pgf{solid}

include("options.jl")

function add_legend!(axis::Axis; kwargs...)
    if haskey(kwargs, :legend)
        if kwargs[:legend] isa AbstractString
            push!(axis, LegendEntry(kwargs[:legend]))
        else
            push!(axis, Legend(kwargs[:legend]...))
        end
    end
    axis
end

# standard plot
function plot(plts::Plot...; kwargs...)
    axis = Axis(default_axis_options(), plts...)
    set_axis_options!(axis; kwargs...)
    add_legend!(axis; kwargs...)
    axis
end

# group plot
function plot(axes::AbstractArray{<: Union{PGFPlotsX.AxisLike, Nothing}}; kwargs...)
    kwargs = Dict(kwargs)

    #################################
    # apply legend to only one axis #
    #################################
    if haskey(kwargs, :legend_pos_axis)
        I = kwargs[:legend_pos_axis]
    else
        I = (1,1) # default
    end
    if haskey(kwargs, :legend_pos) && kwargs[:legend_pos] == "outer north east"
        add_legend!(axes[1,end]; kwargs...)
    else
        add_legend!(axes[I...]; kwargs...) # default
    end

    #################################
    # apply xlabel only bottom axes #
    #################################
    if haskey(kwargs, :xlabel)
        for I in CartesianIndices(axes)
            if I[1] == size(axes, 1) # bottom
                axes[I] === nothing && continue
                axes[I]["xlabel"] = kwargs[:xlabel]
            end
        end
        delete!(kwargs, :xlabel)
    end

    ###############################
    # apply ylabel only left axes #
    ###############################
    if haskey(kwargs, :ylabel)
        for I in CartesianIndices(axes)
            if I isa CartesianIndex{1} || I[2] == 1 # left
                axes[I] === nothing && continue
                axes[I]["ylabel"] = kwargs[:ylabel]
            end
        end
        delete!(kwargs, :ylabel)
    end

    #########################################################
    # cycle_list_name doesn't affect in group plot options, #
    # so directly put options into each axis.               #
    #########################################################
    if haskey(kwargs, :cycle_list_name)
        for ax in axes
            ax === nothing && continue
            ax["cycle list name"] = kwargs[:cycle_list_name]
        end
        delete!(kwargs, :cycle_list_name)
    end

    # group_style
    dims = string(size(axes, 2), " by ", size(axes, 1))
    group_plot_opt = @pgf{group_style = {group_size = dims}}
    if haskey(kwargs, :horizontal_sep)
        group_plot_opt["group style"]["horizontal sep"] = kwargs[:horizontal_sep]
    end
    if haskey(kwargs, :vertical_sep)
        group_plot_opt["group style"]["vertical sep"] = kwargs[:vertical_sep]
    end

    axis_like = GroupPlot(
        merge!(default_axis_options(), group_plot_opt),
        permutedims(axes)...,
    )
    set_axis_options!(axis_like; kwargs...)
    axis_like
end

# multiple plots in one axis
function plot!(dest::Axis, srcs::Axis...; kwargs...)
    for src in srcs
        merge!(dest.options, src.options)
        append!(dest, src.contents)
    end
    add_legend!(dest; kwargs...)
    # overwrite options
    set_plot_options!(dest; kwargs...)
    set_axis_options!(dest; kwargs...)
    dest
end
function plot(x::Axis, ys::Axis...; kwargs...)
    plot!(Axis(default_axis_options()), x, ys...; kwargs...)
end

# plotobject
function plotobject(args...; kwargs...)
    plt = PlotInc(default_plot_options(), args...)
    set_plot_options!(plt; kwargs...)
    plt
end

function plotobject(coordinates::Coordinates{3}; kwargs...)
    plt = Plot3Inc(default_plot_options(), coordinates)
    set_plot_options!(plt; kwargs...)
    plt
end

_map(f::typeof(identity), x) = x
_map(f, x) = mappedarray(f, x)
function plotobject(x::AbstractArray, y::AbstractArray; xmap = identity, ymap = identity, kwargs...)
    x′ = _map(xmap, x)
    y′ = _map(ymap, y)
    # xmap and ymap options are dropped here
    plotobject(Coordinates(x′, y′); kwargs...)
end
function plotobject(x::AbstractArray, y::AbstractArray, z::AbstractArray; xmap = identity, ymap = identity, zmap = identity, kwargs...)
    x′ = _map(xmap, x)
    y′ = _map(ymap, y)
    z′ = _map(zmap, z)
    # xmap, ymap and zmap options are dropped here
    plotobject(Coordinates(x′, y′, z′); kwargs...)
end

# with functions
function plotobject(x::AbstractVector; kwargs...)
    plotobject(1:length(x), x; kwargs...)
end
function plotobject(x, y::Function; kwargs...)
    plotobject(x, mappedarray(y, x); kwargs...)
end
function plotobject(x::Function, y; kwargs...)
    plotobject(mappedarray(x, y), y; kwargs...)
end
function plotobject(x::Function, y::Function; kwargs...)
    throw(ArgumentError("`plot(::Function, ::Function)` is not supported"))
end

function plot(args...; kwargs...)
    plot(plotobject(args...; kwargs...); kwargs...)
end

function plot(x, ys::Matrix; kwargs...)
    ismultiplotoption(key) = haskey(plot_attributes, key) && isa(kwargs[key], Union{Tuple, AbstractVector})
    plts = map(1:size(ys, 2)) do j
        newkwargs = Dict{Symbol, Any}(
            ismultiplotoption(key) ?
            key => value[j] : key => value
            for (key, value) in pairs(kwargs)
        )
        plotobject(x, view(ys, :, j); newkwargs...)
    end
    plot(plts...; kwargs...)
end
function plot(xs::Matrix, y; plot_options = @pgf{}, kwargs...)
    ismultiplotoption(key) = haskey(plot_attributes, key) && isa(kwargs[key], Union{Tuple, AbstractVector})
    plts = map(1:size(xs, 2)) do j
        newkwargs = Dict{Symbol, Any}(
            ismultiplotoption(key) ?
            key => value[j] : key => value
            for (key, value) in pairs(kwargs)
        )
        plotobject(view(xs, :, j), y; newkwargs...)
    end
    plot(plts...; kwargs...)
end

extract_data(table::CSV.File, not_name) = not_name
extract_data(table::CSV.File, name::Union{Symbol, AbstractString}) = table[name]
extract_data(table::CSV.File, names::Union{Tuple, AbstractVector}) = hcat((table[name] for name in names)...)
function plot(table::CSV.File, names...; kwargs...)
    plot(extract_data.(Ref(table), names)...; kwargs...)
end
plot(filename::AbstractString, names...; kwargs...) = plot(CSV.File(filename; comment="#"), names...; kwargs...)

function scatter(args...; plot_options = @pgf{}, kwargs...)
    plot_options["only marks"] = nothing
    plot(args...; plot_options, kwargs...)
end

function xbar_stacked(args...; axis_options = @pgf{}, kwargs...)
    axis_options["xbar stacked"] = nothing
    axis_options["minor tick num"] = 0
    plot(args...; axis_options, kwargs...)
end
function ybar_stacked(args...; axis_options = @pgf{}, kwargs...)
    axis_options["ybar stacked"] = nothing
    axis_options["minor tick num"] = 0
    plot(args...; axis_options, kwargs...)
end

function plot_fillbetween(x_lower::AbstractVector, y_lower::AbstractVector, x_upper::AbstractVector, y_upper::AbstractVector; kwargs...)
    preamble = raw"\usepgfplotslibrary{fillbetween}"
    !in(preamble, PGFPlotsX.CUSTOM_PREAMBLE) && push!(PGFPlotsX.CUSTOM_PREAMBLE, preamble)

    kwargs = Dict(kwargs)
    if !haskey(kwargs, :opacity) && !haskey(kwargs, :fill_opacity)
        kwargs[:fill_opacity] = "0.2"
    end

    lower = plotobject(x_lower, y_lower; plot_options = @pgf{"name path=lower", no_marks}, kwargs...)
    upper = plotobject(x_upper, y_upper; plot_options = @pgf{"name path=upper", no_marks}, kwargs...)
    fill  = plotobject(raw"fill between [of=lower and upper]"; kwargs...)
    plot(lower, upper, fill; kwargs...)
end
function plot_fillbetween(x::AbstractVector, lower::AbstractVector, upper::AbstractVector; kwargs...)
    plot_fillbetween(x, lower, x, upper; kwargs...)
end

savegraph(filename::String, td; kwargs...) = pgfsave(filename, td; kwargs...)
savegraph(filename::String; kwargs...) = td -> pgfsave(filename, td; kwargs...) # allow use of `plot(...) |> savegraph(filename)`

end # module
