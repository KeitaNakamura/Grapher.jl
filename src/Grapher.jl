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
    :xmode => :xmode,
    :ymode => :ymode,
    :zmode => :zmode,
    :symbolic_x_coords => :symbolic_x_coords,
    :symbolic_y_coords => :symbolic_y_coords,
    :symbolic_z_coords => :symbolic_z_coords,
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


fixoptions!(x::Any) = x
function fixoptions!(options::Options)
    if haskey(options, :mark)
        if options[:mark] === nothing
            delete!(options, :mark)
            options[:no_marks] = nothing # set no_marks
        end
    end
    if haskey(options, :line_width)
        options[Symbol(options[:line_width])] = nothing # set line_width
        delete!(options, :line_width)
    end
    if haskey(options, :line_style)
        options[Symbol(options[:line_style])] = nothing # set line_style
        delete!(options, :line_style)
    end
    if haskey(options, :size)
        if options[:size] == "landscape"
            options[:width] = "80mm"
            options[:height] = "50mm"
        elseif options[:size] == "large landscape"
            options[:width] = "140mm"
            options[:height] = "90mm"
        elseif options[:size] == "portrait"
            options[:width] = "50mm"
            options[:height] = "80mm"
        elseif options[:size] == "large portrait"
            options[:width] = "90mm"
            options[:height] = "140mm"
        elseif options[:size] == "square"
            options[:width] = "80mm"
            options[:height] = "80mm"
        elseif options[:size] == "large square"
            options[:width] = "140mm"
            options[:height] = "140mm"
        end
        delete!(options, :size)
    end
    if haskey(options, :smooth)
        if options[:smooth] == true
            options[:smooth] = nothing
        else
            delete!(options, :smooth)
        end
    end

    # for legend style
    !haskey(options, :legend_style) && (options[:legend_style] = @pgf{})
    legend_style = options[:legend_style]
    if haskey(options, :legend_pos)
        if options[:legend_pos] isa String
            if options[:legend_pos] == "outer south"
                legend_style[:at] = Coordinate(0.5, -0.1)
                legend_style[:anchor] = "north"
                legend_style[:legend_columns] = "-1"
                # legend_style[:inner_sep] = "1mm"
                legend_style[:style] = @pgf{column_sep = "2mm"}
                delete!(options, :legend_pos)
            end
        else
            legend_style[:at] = Coordinate(options[:legend_pos]...)
            delete!(options, :legend_pos)
        end
    end
    if haskey(options, :legend_anchor)
        legend_style[:anchor] = options[:legend_anchor]
        delete!(options, :legend_anchor)
    end

    options
end
function fixoptions!(plt::Plot)
    fixoptions!(plt.options)
    plt
end
function GrapherAxis(options::Options, contents...)
    fixoptions!(options)
    foreach(fixoptions!, contents)
    Axis(options, contents...)
end

extract_axis_options(; kwargs...) = Options((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...)
extract_plot_options(; kwargs...) = Options((plot_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(plot_attributes, key))...)
extract_mark_options(; kwargs...) = Options((mark_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(mark_attributes, key))...)

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
    axis = GrapherAxis(
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
        fixoptions!(merge(default_axis_options, axis_options)),
        permutedims(axes)...,
    )
end

# multiple plots in one axis
function plot!(dest::Axis, srcs::Axis...;
               axis_options = @pgf{},
               kwargs...)
    merge!(axis_options, extract_axis_options(; kwargs...))
    merge!(dest.options, fixoptions!(axis_options))
    for src in srcs
        foreach(fixoptions!, src.contents)
        append!(dest, src.contents)
    end
    add_legend!(dest; kwargs...)
    dest
end
function plot(x::Axis, ys::Axis...; kwargs...)
    options = merge(getproperty.((x, ys...), :options)...)
    plot!(GrapherAxis(options), x, ys...; kwargs...)
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

function plot(x, ys::Matrix; kwargs...)
    plts = map(1:size(ys, 2)) do j
        plotobject(x, view(ys, :, j); kwargs...)
    end
    plot(plts...; kwargs...)
end

function plot(xs::Matrix, y; kwargs...)
    plts = map(1:size(xs, 2)) do j
        plotobject(view(xs, :, j), y; kwargs...)
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
    GrapherAxis(axis_option,
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
