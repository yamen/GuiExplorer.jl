module DebugFlags
    const MetricsWindow = Ref(true)
    const PlotMetricsWindow = Ref(true)
    const DebugWindow = Ref(true)
end

metricswindow() = CImGui.ShowMetricsWindow(DebugFlags.MetricsWindow)

plotmetricswindow() = LibCImPlot.ShowMetricsWindow(DebugFlags.PlotMetricsWindow)

function debugwindow()
    Gui.window("Debug", DebugFlags.DebugWindow) do 
        CImGui.Text(Gui.draindebugframe!()) 
    end
end

function frameratewindow()
    Gui.window("Frame Rate") do
        CImGui.ValueFloat("Delta time (ms)", CImGui.GetIO().DeltaTime * 1000, "%.0f")
        CImGui.ValueFloat("Frames per sec", 1 / CImGui.GetIO().DeltaTime, "%.0f")
        CImGui.ValueInt("Frame Count", CImGui.GetFrameCount())
    end
end