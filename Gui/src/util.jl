function getid(id_string::String)
    window = LibCImGui.igGetCurrentWindowRead()
    LibCImGui.ImGuiWindow_GetIDNoKeepAliveStr(window, id_string, id_string)
end

const dumpbuffer = IOBuffer()

debugframe(value) = (Base.dump(dumpbuffer, value); println(dumpbuffer))
draindebugframe!() = String(Base.take!(dumpbuffer))
emptytonull(x::AbstractString) = isempty(x) ? Cstring(C_NULL) : x