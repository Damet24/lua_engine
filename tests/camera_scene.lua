local Scene = require("engine.scene.scene")
local CameraManager = require("engine.camera.cameraManager")

local TestScene = {}
TestScene.__index = TestScene
setmetatable(TestScene, { __index = Scene })

function TestScene.new()
	return setmetatable(Scene.new(), TestScene)
end

function TestScene:onLoad()
	self.cameraManager = CameraManager.new()
	self.cameraManager:add("gameplay", { x = 50, y = 40 })
	self.cameraManager:add("minimap", { zoom = 0.25 })
	self.cameraManager:setActive("gameplay")
end

function TestScene:onDestroy()
	self.cameraManager = nil
end

local scene = TestScene.new()
scene:onLoad()
assert(scene.cameraManager:getActive() == scene.cameraManager:get("gameplay"))
assert(scene.cameraManager:get("minimap") ~= scene.cameraManager:getActive())
scene:onDestroy()
assert(scene.cameraManager == nil)
print("camera scene tests passed")