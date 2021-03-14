function window(inner, title)
    if CImGui.Begin(title)
        inner()
    end
end

function window(inner, title, showflag::Ref{Bool}; flags=ImGuiWindowFlags_None)
    if CImGui.Begin(title, showflag, flags)
        inner()
    end
end