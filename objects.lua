G = {
  Coll=1,
  Sense=2,
  Object=4,
  Harmful=8,
  Player=16,
}

Spawn = class('Spawn')
function Spawn:initialize(obj)
  Game.spawn = {x=obj.object.x, y=obj.object.y}
end

Object = class('Object')
function Object:update(dt)
  for _,c in ipairs( self.body:getContacts()) do
    local f1, f2 = (c.getFixtures or c.getFixtureList)(c)
    local x1, y1 = c:getPositions()
    if (f1 == self.fixture or f2 == self.fixture) then
      local otherfixture = (((f1==self.fixture) and f2) or f1)
      if otherfixture then
        self:_collision(otherfixture, x1 and y1 and true, dt)
        if self.fixture:isDestroyed() then
          break
        end
      end
    end
  end
end

Eggs = {
  quad = love.graphics.newQuad(192,32,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
}

Pearl = class('Pearl', Object)
Pearl.quad = love.graphics.newQuad(160,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
function Pearl:initialize(x,y)
  self.module = self
  self.body = love.physics.newBody(Game.world, x, y, 'dynamic')
  self.shape = love.physics.newCircleShape(4)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  self.fixture:setFilterData(G.Object, G.Coll+G.Object, 0)
end
function Pearl:_collision(otherfixture, ...)
  if otherfixture == Game.player.obj.fixture then
    Game.pearls = Game.pearls + 1
    Game.map:box2d_remove(self.fixture)
  end
end
function Pearl:draw()
  local x,y = self.body:getPosition()
  local r = self.body:getAngle()
  love.graphics.draw(Game.tiles, self.quad, x, y, r, 0.5, 0.5, 16, 16)
end
  
Crab = class('Crab')
Crab.speed = 64
Crab.hp = 5
Crab.quads = {
    love.graphics.newQuad(192,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight()),
    love.graphics.newQuad(192+32,64,32,32,Game.tiles:getWidth(),Game.tiles:getHeight())
}

function Crab:initialize(x,y)
  self.module = self
  self.body = love.physics.newBody(Game.world, x, y, 'dynamic')
  self.body:setFixedRotation(true)
  self.body:setLinearDamping(4)
  self.shape = love.physics.newCircleShape(12)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  self.fixture:setFilterData(G.Harmful, G.Coll+G.Harmful+G.Sense, 0)
  self.fixture:setUserData(self)
  self.dir = 0
  self.hp = self.class.superclass.hp
end

function Crab:update(dt)
  self.body:setGravityScale(1)
  local x, y = self.body:getPosition()
  for _,c in ipairs( self.body:getContacts()) do
    local f1, f2 = (c.getFixtures or c.getFixtureList)(c)
    local x1, y1 = c:getPositions()
    if x1 then
      
      local dir = math.atan2(y1-y,x1-x)
      self.body:setGravityScale(math.max(0,math.cos(dir) * 0.5))
      self.body:applyForce(
        math.cos(dir+math.pi/3) * 500,
        math.sin(dir+math.pi/3) * 500)
      self.dir = dir - math.pi / 2
    end
  end
  if x < 0 then
    Game.eggs = Game.eggs - 1
    Game.map:box2d_remove(self.fixture)
  end
  if self.hp < 0 then
    Game.map:box2d_remove(self.fixture)
    Game.map:box2d_add(Pearl(x,y))
  end
end

function Crab:draw()
  local x,y = self.body:getPosition()
  local r = self.dir
  local alpha = (self.hp / self.class.hp)
  love.graphics.setColor(alpha,alpha,alpha,0.5+alpha/2)
  love.graphics.draw(Game.tiles, self.quads[(math.floor(Game.time *8) % 2) + 1], x, y, r, 1, 1, 16, 16)
  love.graphics.setColor(1,1,1,1)
end
