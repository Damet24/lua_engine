
local ImageLoader = {}

function ImageLoader.load(definition)
    assert(type(definition.path) == "string", "image path is required")

    return love.graphics.newImage(definition.path)
end

function ImageLoader.release(image)
    image:release()
end

return ImageLoader
