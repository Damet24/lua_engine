# Game resolution

The engine uses [Shove 1.0.6](https://github.com/Oval-Tutu/shove/releases/tag/1.0.6)
to draw scenes at the logical resolution configured by `rendering.width` and
`rendering.height`. `window.width` and `window.height` configure the initial
window independently. Shove handles LÖVE resize events automatically.

`rendering.pixelPerfect = false` scales proportionally to fit the window;
`true` uses integer scaling and nearest-neighbor filtering. In integer mode,
a window smaller than the logical resolution clips the viewport rather than
scaling down. Areas outside the viewport use LÖVE's background color.

Scenes can use `context.viewport.screenToViewport(x, y)` to convert screen
coordinates into logical coordinates. It returns `inside, x, y`.

Shove is a shared module, so only one engine should render at a time. The
vendored copy includes a local-scope fix and suppresses messages when its
optional profiler is absent. Its license is in `lua/lib/shove/LICENSE`.