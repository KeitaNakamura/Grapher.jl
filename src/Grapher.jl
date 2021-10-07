module Grapher

using Reexport

using PGFPlotsX
using PGFPlotsX: Options as Opts
@reexport using LaTeXStrings

export
    plot,
    plot!,
    scatter,
    plot_fillbetween

const axis_attributes = Dict(
    :xlabel => :xlabel,
    :ylabel => :ylabel,
    :xmin => :xmin,
    :ymin => :ymin,
    :legend_pos => :legend_pos,
    :minorticks => :minor_tick_num,
)
const plot_attributes = Dict(
    :marker => :mark,
    :color => :color,
    :fill => :fill,
    :opacity => :opacity,
)
const mark_attributes = Dict(
    :marker_fill => :fill,
    :marker_scale => :scale,
)

const default_axis_options = @pgf{legend_cell_align = "left"}
const default_plot_options = @pgf{}
const default_mark_options = @pgf{}

function plot(x, y;
              axis_options = @pgf{},
              plot_options = @pgf{},
              mark_options = @pgf{},
              kwargs...)
    merge!(axis_options, Opts((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...))
    merge!(plot_options, Opts((plot_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(plot_attributes, key))...))
    merge!(mark_options, Opts((mark_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(mark_attributes, key))...))

    if haskey(plot_options, :mark)
        if plot_options[:mark] === nothing
            delete!(plot_options, :mark)
            merge!(plot_options, @pgf{no_marks})
        end
    end

    Axis(
        merge(default_axis_options, axis_options),
        PlotInc(
            merge(
                default_plot_options, plot_options,
                Opts(:mark_options => merge(default_mark_options, mark_options))
            ),
            Coordinates(x, y)
        ),
        (haskey(kwargs, :legend) ? (LegendEntry(kwargs[:legend]),) : ())...
    )
end

function plot(x::Axis, ys::Axis...; kwargs...)
    options = merge(getproperty.((x, ys...), :options)...)
    plot!(Axis(options), x, ys...; kwargs...)
end

function plot!(dest::Axis, srcs::Axis...; kwargs...)
    axis_options = Opts((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...)
    merge!(dest.options, axis_options)
    for src in srcs
        append!(dest, src.contents)
    end
    dest
end

function scatter(x, y; kwargs...)
    plot(x, y; axis_options = @pgf{only_marks}, kwargs...)
end

function plot_fillbetween(x_lower::AbstractVector, lower::AbstractVector, x_upper::AbstractVector, upper::AbstractVector; kwargs...)
    push!(PGFPlotsX.CUSTOM_PREAMBLE, raw"\usepgfplotslibrary{fillbetween}")
    axis_option = Opts((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...)
    fill_option = Opts((plot_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(plot_attributes, key))...)
    line_option = @pgf{}
    if !haskey(fill_option, :opacity)
        fill_option[:opacity] = 0.1
    end
    if haskey(kwargs, :color)
        line_option[:color] = kwargs[:color]
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

end # module
