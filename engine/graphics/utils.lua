local function loadAnimation(image, frameWidth, frameHeight, frameDuration)
	local width, height = image:getDimensions()

	local frames = {}

	for y = 0, height - frameHeight, frameHeight do
		for x = 0, width - frameWidth, frameWidth do
			frames[#frames + 1] = love.graphics.newQuad(x, y, frameWidth, frameHeight, width, height)
		end
	end

	return {
		image = image,
		frames = frames,
		frameDuration = frameDuration,
	}
end

local function loadQuads(image, Width, Height)
	local width, height = image:getDimensions()

	local quads = {}

	for y = 0, height - Height, Height do
		for x = 0, width - Width, Width do
			quads[#quads + 1] = love.graphics.newQuad(x, y, Width, Height, width, height)
		end
	end

	return {
		image = image,
		quads = quads
	}
end

return {
	loadAnimation = loadAnimation,
	loadQuads = loadQuads
}