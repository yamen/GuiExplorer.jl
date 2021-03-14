unchangedplotlimits(plotinfo::PlotInfo) = xmin(plotinfo), xmax(plotinfo), ymin(plotinfo), ymax(plotinfo)

function initialdatafitter(xs, highs, lows)
    if (plotinfo.Reset)
        xs[1], xs[end], minimum(lows), maximum(highs)
    else
        unchangedplotlimits(plotinfo)
    end
end

function visibledatafitter(plotinfo::PlotInfo, xs, highs, lows)
    if (plotinfo.Reset)
        xs[1], xs[end], minimum(lows), maximum(highs)
    else
        x1 = max(1, round(Int, xmin(plotinfo)))
        x2 = min(length(xs), round(Int, xmax(plotinfo)))
        low = minimum(view(lows, x1:x2))
        high = maximum(view(highs, x1:x2))
        xmin(plotinfo), xmax(plotinfo), low, high
    end
end

#= 
A finplot is like a regular plot except:
- it takes in x values + y values for highs / lows
- it only allows zooming on x-axis
- it dynamically calculates y limits based on visible data from x range
- it calculates visible x1 / x2 indices and makes these available for inner functions (to draw only relevant data if needed) =#
function finplot(inner, title_id::String, x_label::AbstractString, y_label::AbstractString, size::Tuple{Real,Real},
    xs, highs, lows;
    xaxislink::Int=0,
    flags::ImPlotFlags_=ImPlotFlags_None,
    x_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None,
    y_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None,
    y2_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None,
    y3_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None)

    plotid = getid(title_id)
    plotinfo = getplotinfo(plotid)

    if xaxislink > 0
        linkxaxis!(plotinfo, xaxislink)
    end

    if plotinfo.Reset || changedlastframe(plotinfo.PlotLimits)
        x1, x2, y1, y2 = visibledatafitter(plotinfo, xs, highs, lows)
        ImPlot.SetNextPlotLimits(x1, x2, y1, y2, CImGui.ImGuiCond_Always)
        plotinfo.Reset = false

        # linked axis may not pull changes until next frame, so let's force a frame refresh
        if xaxislink > 0
            touch!()
        end
    end 

    sizev2 = ImVec2(convert(Float32, size[1]), convert(Float32, size[2]))

    if LibCImPlot.BeginPlot(title_id, emptytonull(x_label), emptytonull(y_label), sizev2, flags, x_flags, ImPlot.ImPlotAxisFlags_Lock, ImPlot.ImPlotAxisFlags_Lock, ImPlot.ImPlotAxisFlags_Lock)
        plotinfo.PlotLimits[] = LibCImPlot.GetPlotLimits()

        x1 = max(1, round(Int, xmin(plotinfo)))
        x2 = min(length(xs), round(Int, xmax(plotinfo)))

        inner(plotinfo, x1, x2)

        if ImPlot.IsPlotHovered() && CImGui.IsMouseDoubleClicked(0)
            plotinfo.Reset = true
        end

        LibCImPlot.EndPlot()
    end

    plotid
end

function candlestick(label, xs, opens, closes, lows, highs, bearcolor, bullcolor, x1, x2)
    drawlist = ImPlot.GetPlotDrawList()
    count = x2 - x1
    halfwidth = (xs[2] - xs[1]) * 0.25

    if ImPlot.BeginItem(label, -1)

        if ImPlot.FitThisFrame()
            low = minimum(view(lows, x1:x2))
            high = maximum(view(highs, x1:x2))
            ImPlot.FitPoint(ImPlot.ImPlotPoint(xs[x1], low))
            ImPlot.FitPoint(ImPlot.ImPlotPoint(xs[x2], high))
        end

        open_pos = Ref{CImGui.ImVec2}()
        close_pos = Ref{CImGui.ImVec2}()
        low_pos = Ref{CImGui.ImVec2}()
        high_pos = Ref{CImGui.ImVec2}()

        for i = x1:x2
            color = opens[i] > closes[i] ? bearcolor : bullcolor
            
            ImPlot.PlotToPixels(low_pos, xs[i], lows[i])
            ImPlot.PlotToPixels(high_pos, xs[i], highs[i])

            CImGui.AddLine(drawlist, low_pos[], high_pos[], color)

            if (count < 500)
                ImPlot.PlotToPixels(open_pos, xs[i] - halfwidth, opens[i])
                ImPlot.PlotToPixels(close_pos, xs[i] + halfwidth, closes[i])

                CImGui.AddRectFilled(drawlist, open_pos[], close_pos[], color)
            end
        end

        ImPlot.EndItem()
    end
end

function lineonclose(label, xs, closes, x1, x2)
    ImPlot.PlotLine(view(xs, x1:x2), view(closes, x1:x2); label=label)
end