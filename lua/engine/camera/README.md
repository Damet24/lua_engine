# Scene cameras

Each scene can create its own `CameraManager` and release it in `onDestroy`.
No cameras are selected automatically. Removing the active camera clears the
active selection; `getActive()` returns `nil` until another camera is selected.
Duplicate identifiers and references to missing cameras raise errors.

```lua
local CameraManager = require("lua.engine.camera.cameraManager")

function Level:onLoad()
    local width, height = self.context.viewport.getViewportDimensions()
    self.cameraManager = CameraManager.new()
    self.cameraManager:add("world", {
        x = width / 2, y = height / 2,
        viewport = { width = width, height = height },
    })
    self.cameraManager:add("overview", {
        x = 200, y = 200, zoom = 0.25,
        viewport = { x = 300, y = 10, width = 90, height = 90, clip = true },
    })
    self.cameraManager:setActive("world")
end

function Level:draw()
    self.cameraManager:getActive():draw(function() self.pipeline:draw() end)
    self.cameraManager:get("overview"):draw(function() self.pipeline:draw() end)
    -- Draw screen-space UI here.
end
```

Camera positions are world coordinates at the viewport center. Defaults are
position `(0, 0)`, zoom `1`, and rotation `0` radians. A viewport uses logical
coordinates, defaults to `(0, 0)` and, if omitted, uses the current LÖVE drawing
target's dimensions. Set it explicitly when using a virtual resolution. Zoom
must be positive. `setViewport` changes the viewport; pass `nil` to reset it.
With `clip = true`, the viewport intersects the existing scissor. The outer
graphics transform must be axis-aligned, as with Shove's scaling and translation.

`cameraCoords` and `worldCoords` convert between world and logical viewport
coordinates, not physical screen coordinates. For mouse input, first call
`context.viewport.screenToViewport`, check its `inside` result, and then call
`camera:worldCoords(x, y)` with the logical coordinates.

Use `camera:draw(function)` to restore the graphics stack and scissor if drawing
fails, including pushes left open by a failing renderer. The callback must not
pop the camera's own graphics stack. `attach` and `detach` are also available
for callers that manage cleanup themselves. A camera cannot be attached twice
at once; different camera instances may be used independently.

The adapter uses the unmodified `hump.camera` module from commit `40f0820`.
Its license is included in the vendored module.