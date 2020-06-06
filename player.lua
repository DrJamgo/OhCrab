--
-- Copyright DrJamgo@hotmail.com 2020
--

require 'utils/vec'
require 'tools'

Player = class('Player')
Player.tools = {
  Gun(),
  Shovel(),
  TowerTool(Tower1),
  TowerTool(Tower2),
  TowerTool(Tower3),
  TowerTool(Tower4),
}
function Player:initialize(obj)
  self.obj = obj
  Game.player = self
  self.obj.body:setMass(50)
  self.obj.body:setFixedRotation(true)
  self.obj.fixture:setFriction(0)
  self.legstime = 0
  self.face = 1
  self.tool = Player.tools[1]
  self:setFilterData()
end

function Player:setFilterData()
  self.obj.fixture:setFilterData(G.Coll+G.Player,G.Coll+G.Object+G.Harmful, 0)
end

function Player:findGround()
  local fmin = 1
  local min = nil
  local fmax = 1
  local max = nil 
  local raydist = (self.leg1 or self.leg2) and 64 or 48
  local x,y = self.obj.body:getPosition()
  Game.world:rayCast(x-4 * self.face, y, x-4* self.face, y+raydist,
    function (fixture, x, y, xn, yn, f)
      if fixture:getFilterData() ~= G.Sense and f < fmin then
        min = {x=x, y=y}
        fmin = f
      end
      return 1
    end
  )
  local x,y = self.obj.body:getPosition()
  Game.world:rayCast(x+4* self.face, y, x+4* self.face, y+raydist,
    function (fixture, x, y, xn, yn, f)
      if fixture:getFilterData() ~= G.Sense and f < fmax then
        max = {x=x, y=y}
        fmax = f
      end
      return 1
    end
  )
  self.ground = max or min
  return math.min(fmin,fmax) * raydist
end

function Player:findPointer()
  local cx,cy = love.mouse.getPosition()
  local wx,wy = Game.transform:inverseTransformPoint(cx,cy)
  local fmin = 1
  local raydist = self.tool.range
  local tile = nil
  local x,y = self.obj.body:getPosition()
  local v = vec2_norm(vec2(wx-x,wy-y))
  self.face = ((v.x > 0) and 1) or -1
  self.dir = math.atan2(v.y,v.x)
  local x2,y2 = x+raydist*v.x, y+raydist*v.y
  local min = nil
  self.pointerfixture = nil
  
  Game.world:rayCast(x, y, x2,y2,
    function (fixture, x, y, xn, yn, f)
      if f < fmin then
        min = {x=x, y=y, xn=xn, yn=yn}
        fmin = f
        self.pointerfixture = fixture
      end
      return 1
    end
  )
  
  if self.pointertile then
    Game.map:setLayerTile('HUD', self.pointertile.tx, self.pointertile.ty, 0)
    self.pointertile = nil
  end
  
  if self.facingtile then
    Game.map:setLayerTile('HUD', self.facingtile.tx, self.facingtile.ty, 0)
    self.facingtile = nil
  end
  
  if min then
    tile = {
      tx=math.floor(1+(min.x-min.xn) / Game.map.tilewidth),
      ty=math.floor(1+(min.y-min.yn) / Game.map.tileheight)
    }
    facing = {
      tx=math.floor(1+(min.x+min.xn) / Game.map.tilewidth),
      ty=math.floor(1+(min.y+min.yn) / Game.map.tileheight),
      dir=math.floor(math.atan2(min.yn,min.xn) / math.pi * 2) % 4 + 1,
      xn=min.xn,
      yn=min.yn
    }
    if validateTile(tile) and validateTile(facing) then
      self.tool:point(tile, facing)
      self.pointertile = tile
      self.facingtile = facing
    end
  end
  
  self.pointer = min
  return fmin * raydist
end

function Player:update(dt)
  
  local distToGround = math.max(4, self:findGround())
  self:findPointer()
  local x,y = self.obj.body:getPosition()
  local vx, vy = self.obj.body:getLinearVelocity()
  local newvx, newvy = vx,vy
  if love.keyboard.isDown('a') then
    newvx = -96
  elseif love.keyboard.isDown('d') then
    newvx = 96
  else
    newvx = 0
  end
  
  self.legstime = self.legstime + dt
  if self.legstime > 0.2 then
    self.leg2 = self.leg1
  end
  if self.ground then
    if self.legstime > 0.2 then
      self.leg1 = self.ground
    end
  else
    self.leg1 = nil
  end

  if self.legstime > 0.2 then
    self.legstime = 0
  end

  if love.keyboard.isDown('w') or love.keyboard.isDown('space') then
    if self.leg1 or self.leg2 then
      newvy = -128
    end
  else
    self.obj.body:applyForce(0,-300000 / distToGround / distToGround / distToGround)
  end
  
  self.obj.body:setLinearVelocity(newvx,newvy)
  self.tool:update(dt)
end

function Player:draw()
  local x,y = self.obj.body:getPosition()
  if Game.options.b and self.ground then
    love.graphics.line(x,y,self.ground.x,self.ground.y)
  end
  if Game.options.b and self.pointer then
    love.graphics.line(x,y,self.pointer.x,self.pointer.y)
  end
  love.graphics.setColor(0,0,0,1)
  if self.leg1 then
    love.graphics.line(x,y,self.leg1.x,self.leg1.y)
    local quad = love.graphics.newQuad(32,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
    love.graphics.draw(Game.tiles, quad, self.leg1.x, self.leg1.y, 0, self.face or 1, 1, 16, 16)
  end
  if self.leg2 then
    love.graphics.line(x,y,self.leg2.x,self.leg2.y)
    local quad = love.graphics.newQuad(32,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
    love.graphics.draw(Game.tiles, quad, self.leg2.x, self.leg2.y, 0, self.face or 1, 1, 16, 16)
  end
  love.graphics.setColor(1,1,1,1)
  local quad = love.graphics.newQuad(0,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
  love.graphics.draw(Game.tiles, quad, x, y, 0, self.face or 1, 1, 16, 16)
  
  if self.tool.draw then
    self.tool:draw()
  end
end