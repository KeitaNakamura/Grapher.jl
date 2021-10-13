function fix_axis_options!(options::Options)
    # size of figure
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

    # for legend style
    if !haskey(options, :legend_style)
        options[:legend_style] = @pgf{}
    end
    legend_style = options[:legend_style]
    if haskey(options, :legend_pos)
        if options[:legend_pos] isa String
            # allow `legend_pos = "outer south"`
            if options[:legend_pos] == "outer south"
                legend_style[:at] = Coordinate(0.5, -0.1)
                legend_style[:anchor] = "north"
                legend_style[:legend_columns] = "-1"
                # legend_style[:inner_sep] = "1mm"
                legend_style[:style] = @pgf{column_sep = "2mm"}
                delete!(options, :legend_pos)
            end
        else
            # allow `legend_pos = (x, y)`
            legend_style[:at] = Coordinate(options[:legend_pos]...)
            delete!(options, :legend_pos)
        end
    end
    if haskey(options, :legend_anchor)
        legend_style[:anchor] = options[:legend_anchor]
        delete!(options, :legend_anchor)
    end

    # tick
    for name in (:xtick, :ytick, :ztick)
        if haskey(options, name)
            if options[name] isa Union{Vector{<: AbstractString}, Tuple{Vararg{AbstractString}}}
                options[Symbol(:symbolic_, string(name)[1], :_coords)] = collect(options[name])
                options[name] = "data"
            end
            if options[name] isa Tuple
                options[name] = collect(options[name])
            end
        end
    end
end

function fix_plot_options!(options::Options)
    # give only `{key}` not `{key = value}`
    key_options = [:line_width, :line_style]
    for name in key_options
        if haskey(options, name)
            pgf_name = Symbol(options[name])
            options[pgf_name] = nothing
            delete!(options, name)
        end
    end

    # on/off options
    on_off_options = [:smooth, :only_marks, :no_marks]
    for name in on_off_options
        if haskey(options, name)
            if options[name] == true
                options[name] = nothing
            else
                delete!(options, name)
            end
        end
    end

    # allow `marker = nothing`
    if haskey(options, :mark)
        if options[:mark] === nothing
            delete!(options, :mark)
            options[:no_marks] = nothing # set no_marks
        end
    end
end

fix_options!(x::Any) = x

function fix_options!(options::Options)
    fix_axis_options!(options)
    fix_plot_options!(options)
    options
end

function fix_options!(o::Union{PGFPlotsX.OptionType, PGFPlotsX.AxisLike})
    for name in propertynames(o)
        fix_options!(getproperty(o, name))
    end
    o
end
