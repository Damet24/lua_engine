local TilemapRender = {}
TilemapRender.__index = TilemapRender

function TilemapRender.new(map, tilesets)
	local self = setmetatable({}, TilemapRender)
	self.map = map
	self.tilesets = tilesets
	return self
end

function TilemapRender:renderLayer(layer)
	local layerWidth = layer.width or self.map.width
	local layerHeight = layer.height or self.map.height
	local offsetX = (layer.x or 0) * self.map.tilewidth + (layer.offsetx or 0)
	local offsetY = (layer.y or 0) * self.map.tileheight + (layer.offsety or 0)
	local opacity = layer.opacity or 1

	love.graphics.push("all")
	love.graphics.setColor(1, 1, 1, opacity)

	for row = 0, layerHeight - 1 do
		for col = 0, layerWidth - 1 do
			local tileGid = layer.data[row * layerWidth + col + 1] or 0

			if tileGid > 0 then
				for tilesetIndex, tilesetInfo in ipairs(self.map.tilesets) do
					local firstGid = tilesetInfo.firstgid
					local nextTileset = self.map.tilesets[tilesetIndex + 1]
					local isInTileset = tileGid >= firstGid
						and (not nextTileset or tileGid < nextTileset.firstgid)

					if isInTileset then
						local tileset = self.tilesets[tilesetInfo.name]
						local quad = tileset and tileset.quads[tileGid - firstGid + 1]

						if quad then
							local x = offsetX + col * self.map.tilewidth
							local y = offsetY + row * self.map.tileheight
							love.graphics.draw(tileset.image, quad, x, y)
						end

						break
					end
				end
			end
		end
	end

	love.graphics.pop()
end

function TilemapRender:submit(pipeline)
	for index, layer in ipairs(self.map.layers) do
		if layer.type == "tilelayer" and layer.visible ~= false then
			local renderLayer = layer.properties and layer.properties.layer
			pipeline:add(renderLayer or index, function()
				self:renderLayer(layer)
			end)
		end
	end
end

function TilemapRender:render()
	for _, layer in ipairs(self.map.layers) do
		if layer.type == "tilelayer" and layer.visible ~= false then
			self:renderLayer(layer)
		end
	end
end

return TilemapRender
