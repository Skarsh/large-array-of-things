-- Run from the project root:
-- aseprite -b --script scripts/build_spritesheet.lua
-- Edit source/spritesheet.aseprite, then run this to export the runtime PNG.
-- Add --script-param check=true before --script to verify without writing.
local root = app.params.root or "."
local size, columns = 32, 3

-- Row order matches Sprite_ID in sprites.odin (excluding None).
local entries = {
  "player_ship", "bullet", "alien",
  "laser_cannon", "plasma_cannon", "missile_launcher",
  "laser_bolt", "plasma_orb", "missile",
}

local sprite = Sprite { fromFile = root .. "/data/sprites/source/spritesheet.aseprite" }
assert(sprite.width == columns * size and sprite.height == math.ceil(#entries / columns) * size,
  "Sheet dimensions must match the grid in sprites.odin")
assert(#sprite.frames == 1, "The runtime expects one static spritesheet frame")
assert(#sprite.slices == #entries, "Sprite slices must match Sprite_ID in sprites.odin")
local slices = {}
for _, slice in ipairs(sprite.slices) do slices[slice.name] = slice end
for i, name in ipairs(entries) do
  local x = ((i - 1) % columns) * size
  local y = math.floor((i - 1) / columns) * size
  local bounds = Rectangle(x, y, size, size)
  if name == "bullet" then bounds = Rectangle(x + 13, y + 10, 6, 12) end
  assert(slices[name] and slices[name].bounds == bounds,
    name .. " slice must match sprite_rect in sprites.odin")
end

local sheet = Image(sprite.width, sprite.height, ColorMode.RGB)
sheet:drawSprite(sprite, 1)
local output = root .. "/data/sprites/spritesheet.png"
if app.params.check == "true" then
  local exported = Image { fromFile = output }
  assert(exported.width == sheet.width and exported.height == sheet.height,
    "Exported PNG dimensions do not match the Aseprite source")
  for y = 0, sheet.height - 1 do for x = 0, sheet.width - 1 do
    assert(exported:getPixel(x, y) == sheet:getPixel(x, y),
      "Spritesheet PNG is stale; run the export script")
  end end
  print("Verified spritesheet PNG and all nine named slices")
else
  sheet:saveAs(output)
  print("Exported " .. sprite.width .. "x" .. sprite.height .. " sheet with " .. #entries .. " sprites")
end
sprite:close()
