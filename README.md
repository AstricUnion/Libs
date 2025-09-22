# Our libs
There is some libs:
* astrobase.lua - base for all bots, can make main bot mechanic in few lines
* ftimers.lua - timers with fractions, very useful for animations (thanks to hamache: https://github.com/ham-ache/l2d-timerlib)
* guns.lua - guns, projectiles for bots
* holos.lua - very easy hologram creator
* light.lua - Server-side light.create
* sounds.lua - Server-side preload and play sounds within bass.loadUrl (REQUIRES NOBLOCK SOUNDS)
* ui.lua - UI library for Astro HUD, but you may find something interesting in it

## Include it in your bot or other chip:
```lua
--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/astrobase.lua as astrobase
require("astrobase")

--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/ftimers.lua as ftimers
require("ftimers")

--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/guns.lua as guns
require("guns")

--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
require("holos")

--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/light.lua as light
require("light")

--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/sounds.lua as sounds
require("sounds")

--@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/ui.lua as ui
require("ui")
```

# TODO
- [x] Merge movement and astrobase in one lib
- [ ] Make guns Blaster and BlasterProjectile a inheritance class
- [ ] Make more UI elements
- [ ] Make 3D UI
- [ ] Refactor FTimers
- [ ] Refactor AstroBase
