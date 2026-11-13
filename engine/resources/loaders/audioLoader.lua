
local AudioLoader = {}

function AudioLoader.load(definition)
    assert(type(definition.path) == "string", "audio path is required")
    assert(
        definition.soundType == "static" or definition.soundType == "stream",
        "soundType must be 'static' or 'stream'"
    )

    return love.audio.newSource(definition.path, definition.soundType)
end

function AudioLoader.release(source)
    source:release()
end

return AudioLoader
