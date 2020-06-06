--
-- Copyright DrJamgo@hotmail.com 2020
--

function love.mousepressed(x,y,button)
  if button == 1 and Game.player.tool then
    Game.player.tool:activate()
  end
end

function love.wheelmoved(x,y)
  for i = 1, #Game.player.tools do
    if Game.player.tools[i] == Game.player.tool then
      local new = i-y
      if new > #Game.player.tools then
        new = 1
      elseif new < 1 then
        new = #Game.player.tools
      end
      Game.player.tool = Game.player.tools[new]
      break
    end
  end

end

function validateTile(tile)
  return tile.tx > 1 and tile.ty > 1 and tile.tx < Game.map.width and tile.ty < Game.map.height
end

selectorQuad = love.graphics.newQuad(64,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())

Dirt = class('Dirt')
function Dirt:initialize(obj)
  obj.body:setType('static')
end

Tool = class('Tool')
Tool.range = 0
function Tool:inizialize()
end
function Tool:update(dt)
end
function Tool:activate()
end
function Tool:point()
end

Shovel = class('Shovel', Tool)
Shovel.range = 32
Shovel.quad = love.graphics.newQuad(32,96,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())

function Shovel:activate()
  local player = Game.player
  if player.pointertile and player.facingtile then
    local tile = Game.map.layers.Tiles.data[player.pointertile.ty][player.pointertile.tx]
    local other = Game.map.layers.Tiles.data[player.facingtile.ty][player.facingtile.tx]
    if tile then
      local othergid = (other and other.gid) or 0
      local gid = tile.gid
      if gid == 1 and othergid == 0 then
        Game.map:setLayerTile('Tiles', player.pointertile.tx, player.pointertile.ty, 0)
        Game.map:setLayerTile('Tiles', player.facingtile.tx, player.facingtile.ty, 1)
        local body = player.pointerfixture:getBody()
        local x,y = body:getPosition()
        body:setPosition(
          x+player.facingtile.xn * Game.map.tilewidth,
          y+player.facingtile.yn * Game.map.tileheight)
        player.obj.body:setPosition(x,y)
      end
    end
  end
end

function Shovel:point(tile, facing)
  Game.map:setLayerTile('HUD', tile.tx, tile.ty, 20)
  Game.map:setLayerTile('HUD', facing.tx, facing.ty, 21)
end

function Shovel:draw()
  local x,y = Game.player.obj.body:getPosition()
  love.graphics.draw(Game.tiles, self.quad, x, y, Game.player.dir, 1, Game.player.face, 16, 16)
end

Gun = class('Gun', Tool)
Gun.range = 150
Gun.force = 1000
Gun.quad = love.graphics.newQuad(0,96,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())

function Gun:update(dt)
  self.min = nil
  if love.mouse.isDown(1) then
    local cx,cy = love.mouse.getPosition()
    local wx,wy = Game.transform:inverseTransformPoint(cx,cy)
    local fmin = 1
    local raydist = self.range
    local x,y = Game.player.obj.body:getPosition()
    local v = vec2_norm(vec2(wx-x,wy-y))
    local x2,y2 = x+raydist*v.x, y+raydist*v.y
    
    local pointerfixture
    Game.world:rayCast(x, y, x2,y2,
      function (fixture, x, y, xn, yn, f)
        local c = {fixture:getCategory()}
        if f < fmin and c[G.Coll] then
          self.min = {x=x, y=y, xn=xn, yn=yn}
          fmin = f
          pointerfixture = fixture
        end
        return 1
      end
    )
    if pointerfixture then
      pointerfixture:getBody():applyForce(Gun.force*v.x,Gun.force*v.y)
    end
    if not self.min then
      self.min = {x=x+v.x*raydist, y=y+v.y*raydist}
    end
  end
end

function Gun:draw()
  local x,y = Game.player.obj.body:getPosition()
  if self.min then
    love.graphics.setColor(0.8,0.8,1,1)
    love.graphics.line(x,y+5,self.min.x+math.random()*4,self.min.y+math.random()*4)
    love.graphics.setColor(1,1,1,1)
  end
  love.graphics.draw(Game.tiles, self.quad, x, y, Game.player.dir, 1, Game.player.face, 16, 16)
end

Tower1 = class('Tower1')
Tower1.quad = love.graphics.newQuad(64,96,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
Tower1.gid = 27
Tower1.cost = 3
Tower1.range = 64
Tower1.duty = {0.5,0.5}
Tower1.damage = 5
Tower1.force = 300
Tower1.color = {0.5,0.5,0.5,1.0}
function Tower1:initialize(x,y)
  self.module = self
  self.body = love.physics.newBody(Game.world, x, y, 'static')
  self.shape = love.physics.newCircleShape(self.range)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  self.fixture:setFilterData(G.Sense, G.Harmful, 0)
  self.fixture:setSensor(true)
  self.dir = 0
  self.time = 0
end

function Tower1:update(dt)
  local x,y = self.body:getPosition()
  self.target = nil
  for _,c in ipairs( self.body:getContacts()) do
    local f1, f2 = (c.getFixtures or c.getFixtureList)(c)
    local other = ((f1 == self.fixture) and f2) or f1
    if other:getUserData() and other:getUserData().hp then
      local ox,oy = other:getBody():getPosition()
      local blocked = false
      Game.world:rayCast(x, y, ox,oy,
        function (fixture, x, y, xn, yn, f)
          if fixture ~= other and fixture:getFilterData() ~= 0 then
            blocked = true
          end
          return 1
        end
      )
      if not blocked then
        self.dir = math.atan2(oy-y,ox-x)
        self.target = other
        self.min = {x=ox, y=oy}
        break
      end
    end
  end
  
  self.active = false
  self.time = self.time + dt
  if self.target then
    local totalduty = self.duty[1] + self.duty[2]
    if self.time > totalduty then
      self.time = 0
    end
    if self.time < self.duty[1] then
      self.target:getBody():applyForce(
        self.force * math.cos(self.dir),
        self.force * math.sin(self.dir))
      local obj = self.target:getUserData()
      obj.hp = obj.hp - (dt * self.damage)
      self.active = true
    end
  end
end

function Tower1:draw(dt)
  local x,y = self.body:getPosition()
  if self.active then
    love.graphics.setColor(self.color)
    love.graphics.line(x,y,self.min.x+math.random()*4,self.min.y+math.random()*4)
    love.graphics.setColor(1,1,1,1)
  end
  love.graphics.draw(Game.tiles, self.quad, x, y, self.dir, 1, 1, 16, 16)
end

Tower2 = class('Tower2', Tower1)
Tower2.quad = love.graphics.newQuad(96,96,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
Tower2.gid = 28
Tower2.cost = 5
Tower2.range = 96
Tower2.duty = {0.2,1.0}
Tower2.damage = 2
Tower2.force = 1500
Tower2.color = {0.4,0.4,1.0,1.0}

Tower3 = class('Tower3', Tower1)
Tower3.quad = love.graphics.newQuad(128,96,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
Tower3.gid = 29
Tower3.cost = 10
Tower3.range = 64
Tower3.duty = {0.1,0.1}
Tower3.damage = 20
Tower3.force = 100
Tower3.color = {1.0,0.5,0.5,1.0}

Tower4 = class('Tower4', Tower1)
Tower4.quad = love.graphics.newQuad(160,96,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
Tower4.gid = 30
Tower4.cost = 15
Tower4.range = 256
Tower4.duty = {0.1,2}
Tower4.damage = 100
Tower4.force = 100
Tower4.color = {1.0,0.8,0.5,1.0}

TowerTool = class('TowerTool', Tool)
TowerTool.range = 64
function TowerTool:initialize(tower)
  self.quad = tower.quad
  self.tower = tower
  self.cost = tower.cost
  self.gid = tower.gid
end

function TowerTool:point(tile, facing)
  Game.map:setLayerTile('HUD', tile.tx, tile.ty, 20)
  local other = Game.map.layers.Tiles.data[facing.ty][facing.tx]
  local othergid = (other and other.gid) or 0
  if othergid == 0 then 
    Game.map:setLayerTile('HUD', facing.tx, facing.ty, self.gid)
  end
end

function TowerTool:activate()
  local player = Game.player
  if player.facingtile then
    local other = Game.map.layers.Tiles.data[player.facingtile.ty][player.facingtile.tx]
    local othergid = (other and other.gid) or 0
    if Game.pearls >= self.cost and othergid == 0 then
      Game.map:setLayerTile('Tiles', player.facingtile.tx, player.facingtile.ty, 19)
      Game.pearls = Game.pearls - self.cost
      Game.map:box2d_add(self.tower(
          (player.facingtile.tx-0.5) * Game.map.tilewidth, 
          (player.facingtile.ty-0.5) * Game.map.tileheight))
    end
  end
end