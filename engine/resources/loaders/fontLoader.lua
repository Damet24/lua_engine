local FontLoader = {}

function FontLoader.load(definition)
    assert(type(definition.size) == "number", "font size is required")

    return love.graphics.newFont(definition.size)
end

function FontLoader.release(image)
    image:release()
end

return FontLoader
