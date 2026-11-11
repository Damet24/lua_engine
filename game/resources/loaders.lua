return {
	image = {
		load = function(definition)
			return love.graphics.newImage(definition.path)
		end,
		release = function(image)
			image:release()
		end,
	},
	font = {
		load = function(definition)
			return love.graphics.newFont(definition.size)
		end,
		release = function(font)
			font:release()
		end,
	},
}