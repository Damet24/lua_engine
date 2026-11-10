local PhysicsDebugSystem = {}

function PhysicsDebugSystem.draw(world)
	love.graphics.push("all")
	love.graphics.setColor(0, 1, 0, 1)
	for _, body in ipairs(world.physics:getBodies()) do
		for _, fixture in ipairs(body:getFixtures()) do
			local shape = fixture:getShape()
			if shape:getType() == "polygon" then
				love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
			elseif shape:getType() == "circle" then
				local x, y = body:getWorldPoint(shape:getPoint())
				love.graphics.circle("line", x, y, shape:getRadius())
			end
		end
	end
	love.graphics.pop()
end

return PhysicsDebugSystem
