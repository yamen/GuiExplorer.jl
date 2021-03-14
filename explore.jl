using Gui
using Printf

#= for variables where two way binding is desired, make them a Ref in the struct

    checkbox::Ref{Bool} = false
    ImGui.Checkbox("label", checkbox)

for variables where view should be ready only, keep them immutable in struct but then passed as Ref to function

    checkbox::Bool = false
    ImGui.Checkbox("label, Ref(checkbox)) 

Or can put a changing value inside a -mutable- struct and use @c syntax

    checkbox::Bool = false
    @c ImGui.Checkbox("label, &checkbox) =#

Base.@kwdef struct MyModel
    messages::Vector{String} = []
end

using Random

function randomohlc(length)
    xs = Float64.(collect(1:length))
    opens = zeros(length)
    highs = zeros(length)
    lows = zeros(length)
    closes = zeros(length)
    last = 100.0
    for i in 1:length
        opens[i] = last
        highs[i] = last + rand(0.0:5.0)
        lows[i] = last - rand(0.0:5.0)
        closes[i] = rand(lows[i]:highs[i])
        last = closes[i]
    end

    xs, opens, highs, lows, closes
end

xs, opens, highs, lows, closes = randomohlc(10000)
stuff = rand(1:10000, 10000)
stuff2 = rand(1:10000, 10000)

function Gui.buildui(context::GuiContext{MyModel,Any})
    state = context.state

    green = ImGui.GetColorU32(0.000, 1.000, 0.441, 1.0)
    red = ImGui.GetColorU32(0.853, 0.050, 0.310, 1.0)
        
    ImGui.PushStyleVar(Int(ImGui.ImGuiStyleVar_ItemSpacing), ImVec2(0f0, 0f0))
    Gui.window("Candlestick Demo") do # , Ref(true); flags=ImGui.ImGuiWindowFlags_NoScrollbar) do
        height = ImGui.GetContentRegionAvail().y
        Gui.finplot("Candlestick Demo Plot", "", "price", (-1, height * 0.55), xs, highs, lows; xaxislink=1, flags=ImPlot.ImPlotFlags_YAxis2) do plotinfo, x1, x2            
            Gui.candlestick("GOOGL", xs, opens, closes, lows, highs, red, green, x1, x2)    
            ImPlot.SetPlotYAxis(1)
            ImPlot.PlotLine(xs, stuff)
        end
        # probably want to use 'initialdatafitter' here
        Gui.finplot("##line1", "", "ys", (-1, height * 0.15), xs, stuff, stuff; xaxislink=1, x_flags=ImPlot.ImPlotAxisFlags_NoTickLabels) do plotinfo, x1, x2
            ImPlot.PlotLine(xs, stuff)
            ImPlot.SetPlotYAxis(1)
            ImPlot.PlotLine(xs, stuff2)
        end
        # probably want to use 'initialdatafitter' here
        Gui.finplot("##line2", "", "ys", (-1, height * 0.15), xs, stuff, stuff; xaxislink=1, x_flags=ImPlot.ImPlotAxisFlags_NoTickLabels) do plotinfo, x1, x2
            ImPlot.PlotLine(xs, stuff)
        end
        Gui.plot("##line3", "", "ys", (-1, height * 0.15); xaxislink=1, flags=ImPlot.ImPlotFlags_YAxis2, x_flags=ImPlot.ImPlotAxisFlags_NoTickLabels) do plotinfo
            ImPlot.PlotLine(xs, stuff)
            ImPlot.SetPlotYAxis(1)
            ImPlot.PlotLine(xs, stuff2)
        end
        # if ImGui.CollapsingHeader("header3")
        #     Gui.plot("##line3", Cstring(C_NULL), "ys", (-1, -1); xaxislink=1, x_flags=ImPlot.ImPlotAxisFlags_NoTickLabels) do plotinfo
        #         ImPlot.PlotLine(xs, stuff)
        #     end
        # end
        # if ImGui.CollapsingHeader("header4")
        #     Gui.plot("##line4", Cstring(C_NULL), "ys", (-1, height * 0.1); xaxislink=1, x_flags=ImPlot.ImPlotAxisFlags_NoTickLabels) do plotinfo
        #         ImPlot.PlotLine(xs, stuff)
        #     end
        # end
        # if ImGui.CollapsingHeader("header5")
        #     Gui.plot("##line5", Cstring(C_NULL), "ys", (-1, height * 0.1); xaxislink=1, x_flags=ImPlot.ImPlotAxisFlags_NoTickLabels) do plotinfo
        #         ImPlot.PlotLine(xs, stuff)
        #     end
        # end
    end
    ImGui.PopStyleVar(1)
    
    Gui.debugframe(context.state)

    Gui.frameratewindow()
    Gui.DebugFlags.DebugWindow[] && Gui.debugwindow()
    Gui.DebugFlags.MetricsWindow[] && Gui.metricswindow()
    Gui.DebugFlags.PlotMetricsWindow[] && Gui.plotmetricswindow()

    Gui.anychangedthisframe()
end

function Gui.update!(context::GuiContext{MyModel,Any}, message)
    push!(context.state.messages, string(message))
end

context, task = Gui.createandrun(MyModel(), Any; width=2450, height=1300, title="Test", hotloading=true, waitevents=1.0)

Gui.dispatch!(context, "hello")
empty!(context.state.messages)