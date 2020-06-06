--
-- Copyright DrJamgo@hotmail.com 2020
--
love.filesystem.setRequirePath("?.lua;?/init.lua;lua/?.lua;lua/?/init.lua")
APPLICATIONNAME = 'JumpDefense'

require 'middleclass'
love.window.setTitle("Oh!Crab - #icantdraw Game Jam - June 2020")
local font = love.graphics.newFont( 32, 'normal' )
love.graphics.setFont(font)

if arg[#arg] == "-debug" then
  require("mobdebug").start()
end
love.window.setMode(1280,640)

local music = love.audio.newSource('funny_track_with_ringtone_effects_c64_style.ogg', 'stream')
music:setLooping(true)
music:play()

Game = {}
Game.tiles = love.graphics.newImage('tiles.png')
Game.tiles:setFilter('nearest','nearest')
require 'player'
require 'objects'
Game.hud = love.graphics.newImage('hud.png')

STI = require 'sti/sti'
  
function Game.initialize()
  Game.options = {p=true}
  
  Game.transform = love.math.newTransform(0,0,0,1,1)
  Game.map = STI('level1.lua', { "box2d" })
  Game.world = love.physics.newWorld(0, 9.81 * 32)
  Game.map:box2d_init(Game.world)
  Game.pearls = 6
  Game.eggs = 10
  Game.time = 0
  Game.wave = 1
  Game.nextwave = 5
  Game.nextcount = 10
  Game.nextcrab = nil

  for i = 1, 10 do
    local x = math.random() * 1280 - 64 - 64
    Game.map:box2d_add(Pearl(64 + x,0))
  end
  
  Game.map:box2d_add(Crab(640,0))
end

Game.initialize()

function love.update(dt)
  if Game.eggs <= 0 then
    return
  end
  
  local fastforward = (Game.options.f and 10) or 1
  local dt = dt * ((Game.options.p and 0) or (fastforward))
  Game.time = Game.time + dt
  
  if Game.nextwave < 0 then
    local crabinterval = 1 / Game.wave
    if not Game.nextcrab then
      Game.nextcrab = 0 - dt
    else
      Game.nextcrab = Game.nextcrab - dt
    end
    if Game.nextcrab < 0 then
      if Game.nextcount > 0 then
        Game.map:box2d_add(Crab(Game.spawn.x,Game.spawn.y))
        Game.nextcrab = Game.nextcrab + crabinterval
        Game.nextcount = Game.nextcount - 1
      else
        Game.wave = Game.wave + 1
        Game.nextwave = 30
        Game.nextcount = Game.wave * 10
      end
    end
  else
    Game.nextwave = Game.nextwave - dt
  end
  if not Game.options.p then
    Game.world:update(dt)
    Game.map:update(dt)
    Game.map:box2d_foreach(nil, nil, 
      function(obj)
        local mod = obj.module
        if mod and mod.update then
          mod:update(dt)
        end
      end
    )
    Game.player:update(dt)
  end
end

function love.draw()
  love.graphics.clear(0.2,0.3,0.5,0)
  Game.map:draw(nil,nil,1,1)
  love.graphics.replaceTransform(Game.transform)
  Game.map:box2d_foreach(nil, nil, 
    function(obj)
      local mod = obj.module
      if mod and mod.draw then
        love.graphics.setColor(1,1,1,1)
        mod:draw(dt)
      end
    end
  )
  love.graphics.replaceTransform(love.math.newTransform())
  if Game.options.b then
    Game.map:box2d_draw(nil,nil,1,1)
  end
  
  love.graphics.draw(Game.tiles, Eggs.quad, 0, 0, 0, 2, 2)
  love.graphics.print(Game.eggs, 0+64, 14)
  love.graphics.draw(Game.tiles, Pearl.quad, 100, 0, 0, 2, 2)
  love.graphics.print(Game.pearls, 100+64, 14)
  
  love.graphics.print(string.format("Wave #%d",Game.wave), 800,14)
  
  love.graphics.print(Game.nextcount, 1100-32,14)
  love.graphics.draw(Game.tiles, Crab.quads[1], 1100, 0, 0, 2, 2)
  love.graphics.print(string.format("in %ds",Game.nextwave), 1100+64,14)
  
  for i = 1, #Game.player.tools do
    local tool = Game.player.tools[i]
    love.graphics.draw(Game.tiles, tool.quad, 300+i*64-6, -math.pi/4, 0, 2, 2)
    if tool == Game.player.tool then
      love.graphics.draw(Game.tiles, selectorQuad, 300+i*64, 0, 0, 2, 2)
    end
    if tool.cost then
      local color = (Game.pearls >= tool.cost and {0,1,0,1}) or {1,0,0,1}
      love.graphics.print({color,string.format("%2d",tool.cost)}, 300+i*64,48)
      love.graphics.draw(Game.tiles, Pearl.quad, 300+i*64+32,48, 0, 1, 1)
    end
  end

  if Game.options.p then
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle('fill', 0,0, 1280,640)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(Game.hud)
  end
  
  if Game.eggs <= 0 then
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle('fill', 0,0, 1280,640)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf('GAME OVER!\nThey got all your Eggs', 0, 320, 1280, 'center', 0, 1,1)
  end
  
  love.graphics.print('\ndrjamgo.itch.io', 0, 600,0,0.5,0.5)
  love.graphics.printf('Oh!Crab', 0, 600, 1280, 'center')
  love.graphics.printf('Sources:\nhttps://github.com/DrJamgo/OhCrab', 0, 600, 1280*2, 'right', 0, 0.5, 0.5)
  
end

function love.quit()

end

function love.keypressed(key, ...)
  if Game.options[key] then 
    Game.options[key] = nil
  else
    Game.options[key] = true
  end
end