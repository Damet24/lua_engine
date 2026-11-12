
local Map = {}
Map.__index = Map


function Map.new(data, width, height, cellSize)
    local self = setmetatable({}, Map)
    self.data = data
    self.width = width
    self.height = height
    self.cellSize = cellSize
    return self
end

function Map:render()
    
end

return Map