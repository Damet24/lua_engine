local RenderPipeline = {}
RenderPipeline.__index = RenderPipeline

function RenderPipeline.new()
	return setmetatable({ items = {} }, RenderPipeline)
end

function RenderPipeline:add(layer, draw)
	layer = layer or 0
	assert(type(layer) == "number", "render layer must be a number")
	assert(type(draw) == "function", "render item must have a draw function")
	local items = self.items
	items[#items + 1] = { layer = layer, draw = draw, order = #items + 1 }
end

function RenderPipeline:draw()
	table.sort(self.items, function(first, second)
		if first.layer == second.layer then
			return first.order < second.order
		end
		return first.layer < second.layer
	end)
	for _, item in ipairs(self.items) do
		item.draw()
	end
end

function RenderPipeline:clear()
	self.items = {}
end

return RenderPipeline