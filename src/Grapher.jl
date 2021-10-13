module Grapher

using Reexport

using PGFPlotsX
using PGFPlotsX: Options
const savegraph = pgfsave
export @pgf, savegraph

@reexport using LaTeXStrings

using Interpolations


export
    plot,
    plot!,
    scatter,
    xbar_stacked,
    ybar_stacked,
    plot_fillbetween

const axis_attributes = Dict(
    :xlabel => :xlabel,
    :ylabel => :ylabel,
    :zlabel => :zlabel,
    :xmin => :xmin, :xmax => :xmax,
    :ymin => :ymin, :ymax => :ymax,
    :zmin => :zmin, :zmax => :zmax,
    :x_dir => :x_dir,
    :y_dir => :y_dir,
    :z_dir => :z_dir,
    :xaxis => :xmode,
    :yaxis => :ymode,
    :zaxis => :zmode,
    :enlarge_x_limits => :enlarge_x_limits,
    :enlarge_y_limits => :enlarge_y_limits,
    :enlarge_z_limits => :enlarge_z_limits,
    :enlargelimits => :enlargelimits,
    :xtick => :xtick,
    :ytick => :ytick,
    :ztick => :ztick,
    :legend_pos => :legend_pos,
    :legend_columns => :legend_columns,
    :legend_anchor => :legend_anchor,
    :minorticks => :minor_tick_num,
    :width => :width,
    :height => :height,
    :size => :size,
    :cycle_list_name => :cycle_list_name,
    :bar_width => :bar_width,
)
const plot_attributes = Dict(
    :marker => :mark,
    :color => :color,
    :fill => :fill,
    :opacity => :opacity,
    :line_width => :line_width,
    :line_style => :line_style,
    :smooth => :smooth,
    :only_marks => :only_marks,
    :no_marks => :no_marks,
)
const mark_attributes = Dict(
    :marker_fill => :fill,
    :marker_scale => :scale,
)

const default_axis_options =
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
const default_plot_options = @pgf{}
const default_mark_options = @pgf{solid}

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
function plot(plts::Plot...;
              axis_options = @pgf{},
              kwargs...)
    merge!(axis_options, extract_axis_options(; kwargs...))
    axis = Axis(
        merge(default_axis_options, axis_options),
        plts...,
    )
    add_legend!(axis; kwargs...)
    axis
end

# group plot
function plot(axes::AbstractArray{<: Union{PGFPlotsX.AxisLike, Nothing}};
              axis_options = @pgf{},
              kwargs...)
    dims = string(size(axes, 2), " by ", size(axes, 1))
    merge!(axis_options, extract_axis_options(; kwargs...), @pgf{group_style = {group_size = dims}})

    # TODO: should copy options in axes before modifying them?
    #################################
    # apply legend to only one axis #
    #################################
    if haskey(kwargs, :legend_pos_axis)
        I = kwargs[:legend_pos_axis]
    else
        I = (1,1)
    end
    if haskey(kwargs, :legend_pos) && kwargs[:legend_pos] == "outer north east"
        add_legend!(axes[1,end]; kwargs...)
    else
        add_legend!(axes[I...]; kwargs...)
    end

    #################################
    # apply xlabel only bottom axes #
    #################################
    if haskey(kwargs, :xlabel)
        for I in CartesianIndices(axes)
            if I[1] == size(axes, 1)
                axes[I] === nothing && continue
                push!(axes[I].options, :xlabel => kwargs[:xlabel])
            end
        end
        delete!(axis_options, :xlabel)
    end

    ###############################
    # apply xlabel only left axes #
    ###############################
    if haskey(kwargs, :ylabel)
        for I in CartesianIndices(axes)
            if I[2] == 1
                axes[I] === nothing && continue
                push!(axes[I].options, :ylabel => kwargs[:ylabel])
            end
        end
        delete!(axis_options, :ylabel)
    end

    #########################################################
    # cycle_list_name doesn't affect in group plot options, #
    # so directly put options into each axis.               #
    #########################################################
    if haskey(kwargs, :cycle_list_name)
        for ax in axes
            ax === nothing && continue
            push!(ax.options, :cycle_list_name => kwargs[:cycle_list_name])
        end
        delete!(axis_options, :cycle_list_name)
    end

    GroupPlot(
        fix_options!(merge(default_axis_options, axis_options)),
        permutedims(axes)...,
    )
end

# multiple plots in one axis
function plot!(dest::Axis, srcs::Axis...;
               axis_options = @pgf{},
               kwargs...)
    merge!(axis_options, extract_axis_options(; kwargs...))
    merge!(dest.options, fix_options!(axis_options))
    for src in srcs
        foreach(fix_options!, src.contents)
        append!(dest, src.contents)
    end
    add_legend!(dest; kwargs...)
    dest
end
function plot(x::Axis, ys::Axis...; kwargs...)
    options = merge(getproperty.((x, ys...), :options)...)
    plot!(Axis(options), x, ys...; kwargs...)
end

function plotobject(coordinates;
                    plot_options = @pgf{},
                    mark_options = @pgf{},
                    kwargs...)
    merge!(plot_options, extract_plot_options(; kwargs...))
    merge!(mark_options, extract_mark_options(; kwargs...))
    PlotInc(
        merge(
            default_plot_options, plot_options,
            @pgf{mark_options = merge(default_mark_options, mark_options)}
        ),
        coordinates,
    )
end

function plotobject(coordinates::Coordinates{3};
                    plot_options = @pgf{},
                    mark_options = @pgf{},
                    kwargs...)
    merge!(plot_options, extract_plot_options(; kwargs...))
    merge!(mark_options, extract_mark_options(; kwargs...))
    Plot3Inc(
        merge(
            default_plot_options, plot_options,
            @pgf{mark_options = merge(default_mark_options, mark_options)}
        ),
        coordinates,
    )
end

plotobject(x, y; kwargs...) = plotobject(Coordinates(x, y); kwargs...)
plotobject(x, y, z; kwargs...) = plotobject(Coordinates(x, y, z); kwargs...)

function plot(args...; kwargs...)
    plot(plotobject(args...; kwargs...); kwargs...)
end

function extract_eachplot_options(nplots::Int; kwargs...)
    # following options allows collection such as vector and tuple
    option_list = Tuple(keys(plot_attributes))
    eachplot_options = map(1:nplots) do j
        options = @pgf{}
        for name in option_list
            if haskey(kwargs, name)
                if kwargs[name] isa Union{Tuple, AbstractVector}
                    options[plot_attributes[name]] = kwargs[name][j]
                else
                    options[plot_attributes[name]] = kwargs[name]
                end
            end
        end
        options
    end
    # remove options extrated in above code
    newkwargs = Base.structdiff(values(kwargs),
                                NamedTuple{option_list})
    eachplot_options, pairs(newkwargs)
end
function plot(x, ys::Matrix; plot_options = @pgf{}, kwargs...)
    eachplot_options, newkwargs = extract_eachplot_options(size(ys, 2); kwargs...)
    plts = map(1:size(ys, 2)) do j
        plotobject(x, view(ys, :, j);
                   plot_options = merge(plot_options, eachplot_options[j]),
                   newkwargs...)
    end
    plot(plts...; newkwargs...)
end
function plot(xs::Matrix, y; plot_options = @pgf{}, kwargs...)
    eachplot_options, newkwargs = extract_eachplot_options(size(xs, 2); kwargs...)
    plts = map(1:size(xs, 2)) do j
        plotobject(view(xs, :, j), y;
                   plot_options = merge(plot_options, eachplot_options[j]),
                   newkwargs...)
    end
    plot(plts...; kwargs...)
end

function scatter(args...; plot_options = @pgf{}, kwargs...)
    plot_options[:only_marks] = nothing
    plot(args...; plot_options, kwargs...)
end

function xbar_stacked(args...; axis_options = @pgf{}, kwargs...)
    axis_options[:xbar_stacked] = nothing
    axis_options[:ytick] = "data"
    axis_options[:minor_tick_num] = 0
    plot(args...; axis_options, kwargs...)
end
function ybar_stacked(args...; axis_options = @pgf{}, kwargs...)
    axis_options[:ybar_stacked] = nothing
    axis_options[:xtick] = "data"
    axis_options[:minor_tick_num] = 0
    plot(args...; axis_options, kwargs...)
end

struct FillBetween{X_Lower, Y_Lower, X_Upper, Y_Upper}
    x_lower::X_Lower
    y_lower::Y_Lower
    x_upper::X_Upper
    y_upper::Y_Upper
end

function plot_fillbetween(x_lower::AbstractVector, lower::AbstractVector, x_upper::AbstractVector, upper::AbstractVector; kwargs...)
    push!(PGFPlotsX.CUSTOM_PREAMBLE, raw"\usepgfplotslibrary{fillbetween}")
    axis_option = extract_axis_options(; kwargs...)
    line_option = extract_plot_options(; kwargs...)
    fill_option = copy(line_option)
    if !haskey(fill_option, :opacity) && !haskey(kwargs, :fill_opacity)
        fill_option[:opacity] = 0.2
    end
    if haskey(kwargs, :fill_opacity)
        fill_option[:opacity] = kwargs[:fill_opacity]
    end
    if haskey(line_option, :opacity)
        delete!(line_option, :opacity)
    end
    if haskey(kwargs, :borderlines) && kwargs[:borderlines] == false
        line_option[:opacity] = 0.0
    end
    Axis(axis_option,
         Plot(merge(@pgf{"name path=lower", no_marks}, line_option), Coordinates(x_lower, lower)),
         Plot(merge(@pgf{"name path=upper", no_marks}, line_option), Coordinates(x_upper, upper)),
         Plot(fill_option,
              raw"fill between [of=lower and upper]"))
end
function plot_fillbetween(x::AbstractVector, lower::AbstractVector, upper::AbstractVector; kwargs...)
    plot_fillbetween(x, lower, x, upper; kwargs...)
end
function plot(obj::FillBetween; kwargs...)
    plot_fillbetween(obj.x_lower, obj.y_lower, obj.x_upper, obj.y_upper; kwargs...)
end

moving_average(vs, n) = [sum(@view vs[i:(i+n-1)])/n for i in 1:(length(vs)-(n-1))]
function moving_average(x::AbstractVector, y::AbstractVector, n::Int = 10)
    @assert length(x) == length(y)
    x′ = moving_average(x, n)
    y′ = moving_average(y, n)
    isempty(x′) && return plot(), plot()
    interp = LinearInterpolation(x′, y′, extrapolation_bc=Line())
    lower = vcat([[x[i] y[i]] for i in 1:length(x) if y[i] ≤ interp(x[i])]...)
    upper = vcat([[x[i] y[i]] for i in 1:length(x) if y[i] > interp(x[i])]...)
    Coordinates(y′, x′), FillBetween(lower[:,2], lower[:,1], upper[:,2], upper[:,1])
end

function plot_moving_average(x::AbstractVector, y::AbstractVector, n::Int = 10; kwargs...)
    plt1, plt2 = moving_average(x, y, n)
    plot(plot(plt1; kwargs...), plot(plt2; borderlines = false, kwargs...))
end

end # module
