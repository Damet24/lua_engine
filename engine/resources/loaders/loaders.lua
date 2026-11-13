local imageLoader = require "engine.resources.loaders.imageLoader"
local audioLoader = require "engine.resources.loaders.audioLoader"
local FontLoader = require "engine.resources.loaders.fontLoader"

return {
    image = imageLoader,
    sound = audioLoader,
    font = FontLoader,
}
