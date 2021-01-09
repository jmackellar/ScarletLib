local ScarletLib = { }

--- GameState

local gamestate = { }

--- registerGameState
function gamestate.registerGameState(state)
	if love.filesystem.exists(state .. '.lua') then
		local s = require(state)
		table.insert(gameStates, {key = state, state = s, entered = false})
		print('[STATE] Registered ' .. state .. ' as gameState.')
	end
end

--- switchGameState
function gamestate.switchGameState(state)
	for i = 1, # gameStates do
		local g = gameStates[i]
		if g.key == state then
			print('[STATE] Switched to ' .. state .. ' gameState')
			gameState = g.state 
			--- If the state is being entered for the first
			--- time then its load() function will be called.
			if not g.entered and g.state.load then 
				g.entered = true 
				g.state.load()
				if g.state.enter then
					g.state.enter()
				end
			elseif g.entered and g.state.enter then
				g.state.enter()
			end
			break
		end
	end
end

--- getGamestate
function gamestate.getGameState() return gameState end

ScarletLib.gamestate = gamestate

--- Layout

local layout = { }
local elements = { }
local styles = { }

local fonts = { }
local shaders = { }

local hilightedElement = false
local groupsToDelete = { }

---
--- Shaders
---

shaders.removeOutline = { }
shaders.removeOutline.shader = love.graphics.newShader[[
	//Effect
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
   	vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
   	if (pixel.r == 1 && pixel.g == 1 && pixel.b == 1) {
   		pixel.r = 0.35;
   		pixel.g = 0.35;
   		pixel.b = 0.35;
    }
   	return pixel;
 	}
]]

shaders.fade = { }
shaders.fade.shader = love.graphics.newShader[[
	extern number a;
	//Effect
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
   	vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
   	if (pixel.a != 0 && pixel.r != 1 && pixel.g != 1 && pixel.b != 1) {
   		pixel.a = a;
   	}
    else if (pixel.a != 0 && pixel.r == 1 && pixel.g == 1 && pixel.b == 1) {
    	pixel.a = a;
    	pixel.r = 0;
    	pixel.g = 0;
    	pixel.b = 0;
    }
   	else {
   		pixel.a = a;
   	}
   	return pixel;
   }
]]

shaders.fadeOutlineBlue = { }
shaders.fadeOutlineBlue.shader = love.graphics.newShader[[
	extern number time;
	//Effect
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
   	vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
   	if (pixel.r == 1 && pixel.g == 1 && pixel.b == 1) {
   		pixel.r = 0.38;
   		pixel.g = 0.6;
   		pixel.b = 1;
   		pixel.a = pixel.a * time;
    }
   	return pixel;
 	}
]]
shaders.fadeOutlineBlue.time = 1
shaders.fadeOutlineBlue.dt = -1
shaders.fadeOutlineBlue.update =	function (dt)
									shaders.fadeOutlineBlue.time = shaders.fadeOutlineBlue.time + shaders.fadeOutlineBlue.dt * dt * 0.4
									if shaders.fadeOutlineBlue.time <= 0.3 then
										shaders.fadeOutlineBlue.dt = 1
									elseif shaders.fadeOutlineBlue.time >= 1 then
										shaders.fadeOutlineBlue.time = 1
										shaders.fadeOutlineBlue.dt = -1
									end
									shaders.fadeOutlineBlue.shader:send('time', shaders.fadeOutlineBlue.time)
								end

shaders.fadeOutlineRed = { }
shaders.fadeOutlineRed.shader = love.graphics.newShader[[
	extern number time;
	//Effect
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
   	vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
   	if (pixel.r == 1 && pixel.g == 1 && pixel.b == 1) {
   		pixel.r = 1;
   		pixel.g = 0;
   		pixel.b = 0;
   		pixel.a = pixel.a * time;
    }
   	return pixel;
 	}
]]
shaders.fadeOutlineRed.time = 1
shaders.fadeOutlineRed.dt = -1
shaders.fadeOutlineRed.update =	function (dt)
									shaders.fadeOutlineRed.time = shaders.fadeOutlineRed.time + shaders.fadeOutlineRed.dt * dt * 0.4
									if shaders.fadeOutlineRed.time <= 0.3 then
										shaders.fadeOutlineRed.dt = 1
									elseif shaders.fadeOutlineRed.time >= 1 then
										shaders.fadeOutlineRed.time = 1
										shaders.fadeOutlineRed.dt = -1
									end
									shaders.fadeOutlineRed.shader:send('time', shaders.fadeOutlineRed.time)
								end

shaders.fadeOutline = { }
shaders.fadeOutline.shader = love.graphics.newShader[[
	extern number time;
	//Effect
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
   	vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
   	if (pixel.r == 1 && pixel.g == 1 && pixel.b == 1) {
   		pixel.r = pixel.r * time;
   		pixel.g = pixel.g * time;
   		pixel.b = pixel.b * time;
    }
   	return pixel;
 	}
]]
shaders.fadeOutline.time = 1
shaders.fadeOutline.dt = -1
shaders.fadeOutline.update =	function (dt)
									shaders.fadeOutline.time = shaders.fadeOutline.time + shaders.fadeOutline.dt * dt * 0.4
									if shaders.fadeOutline.time <= 0.3 then
										shaders.fadeOutline.dt = 1
									elseif shaders.fadeOutline.time >= 1 then
										shaders.fadeOutline.time = 1
										shaders.fadeOutline.dt = -1
									end
									shaders.fadeOutline.shader:send('time', shaders.fadeOutline.time)
								end

---
--- Callbacks
---

function layout.load()
	styles = {
		{
			corner = love.graphics.newImage("/img/layout/style1corner.png"),
			edge = love.graphics.newImage("/img/layout/style1edge.png"),
		},
		{
			corner = love.graphics.newImage("/img/layout/style2corner.png"),
			edge = love.graphics.newImage("/img/layout/style2edge.png"),
		},
		{
			corner = love.graphics.newImage("/img/layout/style3corner.png"),
			edge = love.graphics.newImage("/img/layout/style3edge.png"),
		},
		{
			corner = love.graphics.newImage("/img/layout/style4corner.png"),
			edge = love.graphics.newImage("/img/layout/style4edge.png"),
		},
		{
			corner = love.graphics.newImage("/img/layout/style5corner.png"),
			edge = love.graphics.newImage("/img/layout/style5edge.png"),
		},
		{
			corner = love.graphics.newImage("/img/layout/style6corner.png"),
			edge = love.graphics.newImage("/img/layout/style6edge.png"),
		},
		{
			corner = love.graphics.newImage("/img/layout/style7corner.png"),
			edge = love.graphics.newImage("/img/layout/style7edge.png"),
		},
	}
	fonts = {
		font1 = love.graphics.newImageFont("/img/layout/font1.png", "1234567890-/ ABCDEFGHIJKLMNOPQRSTUVWXYZ:.'%+()abcdefghijklmnopqrstuvwxyz,>?©!*#", 2),
	}
	print('[LAYOUT] Assets succesfully loaded.')
end

function layout.update(dt)
	--- Delete groups
	layout.deleteFlaggedGroups()
	--- update shaders
	for k,v in pairs(shaders) do
		if v.update then v.update(dt) end
	end
	--- update mouse hilights
	local omouse = mouseover
	local mouseover = false
	for i = 1, # elements do
		if not elements[i].disabled then
			if elements[i].update then
				elements[i].update(game, elements[i])
			end
			if elements[i].type == 'bar' then
				layout.updateBar(elements[i], dt)
			elseif elements[i].type == 'button' then
				elements[i].buttonpressedhilight = elements[i].buttonpressedhilight - dt
			end
			if elements[i].hilightable and love.mouse.getX() >= elements[i].x and love.mouse.getX() <= elements[i].x + elements[i].width and love.mouse.getY() >= elements[i].y and love.mouse.getY() <= elements[i].y + elements[i].height and not mouseover then
				mouseover = elements[i]
			end
			--[[if elements[i].fade and elements[i].fade < 255 then
				shaders.fadeOutline.time = 0.1
			end--]]
			if elements[i].type == 'slider' then
				local e = elements[i]
				local sx = elements[i].x + elements[i].width * (elements[i].startval / elements[i].maxval)
				local mx, my = love.mouse.getPosition()
				local d = math.sqrt((sx - mx)^2 + (e.y - my)^2)
				if mx >= e.x and mx <= e.x + e.width and my >= e.y - 10 and my <= e.y + 10 then
					mouseover = elements[i]
					if love.mouse.isDown(1) then
						local c = (elements[i].x + elements[i].width * (elements[i].startval / elements[i].maxval))
						local cd = mx - c
						elements[i].startval = elements[i].startval + cd
						if elements[i].startval < elements[i].minval then
							elements[i].startval = elements[i].minval 
						elseif elements[i].startval > elements[i].maxval then
							elements[i].startval = elements[i].maxval
						end
					end
				end
			end
		end
	end
	if not mouseover then
		mouseover = omouse 
	end
	hilightedElement = mouseover
end

function layout.draw()
	for i = # elements, 1, -1 do
		if not elements[i].disabled then
			if elements[i].type == 'frame' then
				layout.drawFrame(elements[i])
			elseif elements[i].type == 'img' then
				layout.drawImg(elements[i])
			elseif elements[i].type == 'bar' then
				layout.drawBar(elements[i])
			elseif elements[i].type == 'button' then
				layout.drawButton(elements[i])
			elseif elements[i].type == 'text' then
				layout.drawText(elements[i])
			elseif elements[i].type == 'line' then
				layout.drawLine(elements[i])
			elseif elements[i].type == 'slider' then
				layout.drawSlider(elements[i])
			end
			if hilightedElement and elements[i].name == hilightedElement.name and elements[i].type ~= 'slider' then
				love.graphics.setColor(255, 255, 255, 100)
				love.graphics.rectangle('fill', elements[i].x, elements[i].y, elements[i].width, elements[i].height or 1)
				love.graphics.setColor(255, 255, 255, 255)
			elseif hilightedElement and elements[i].name == hilightedElement.name and elements[i].type == 'slider' then
				love.graphics.setColor(255, 255, 255, 100)
				love.graphics.circle('fill', elements[i].x + elements[i].width * (elements[i].startval / elements[i].maxval), elements[i].y, 7)
				love.graphics.setColor(255, 255, 255, 255)
			end
			love.graphics.setShader()
		end
	end
	if hilightedElement then
		if hilightedElement.hilighttext then
			local text = hilightedElement.hilighttext
			local tw = fonts[hilightedElement.hilightfont]:getWidth(text)
			local sx = math.max(math.floor(hilightedElement.x + (hilightedElement.width / 2) - 25 - tw / 2 ), 2)
			local sy = hilightedElement.y + hilightedElement.height + 4
			local height = 25
			local temp, lines = string.gsub(text, '\n', ' ')
			height = 25 + (lines * 16)
			if sx + 50 + tw >= love.graphics.getWidth() then
				sx = sx - ((sx + 50 + tw) - love.graphics.getWidth()) - 2
			end
			if sy + height + 2 >= love.graphics.getHeight() then
				sy = hilightedElement.y - height - 4
			end
			local frame = {
				style = 2,
				x = sx,
				y = sy,
				width = 50 + tw,
				height = height,
				z = 100,
			}
			layout.drawFrame(frame)
			love.graphics.setFont(fonts.font1)
			love.graphics.print(text, sx + 25, sy + 6)
		end
	end
end

function layout.mousepressed(x, y, button)
	local pressed = false
	for i = # elements, 1, -1 do
		if elements[i] then
			if elements[i].type ~= 'line' and elements[i].type ~= 'slider' and not elements[i].disabled and elements[i].width and x >= elements[i].x and x <= elements[i].x + elements[i].width and y >= elements[i].y and y <= elements[i].y + elements[i].height then
				if elements[i].toggleable and button == 1 then
					if elements[i].toggled then
						elements[i].toggled = false 
						elements[i].offtoggle(elements[i])
					else
						elements[i].toggled = true 
						elements[i].ontoggle(elements[i])
					end
				end
				if elements[i].buttonpressed and button == 1 and not elements[i].toggleable then
					elements[i].buttonpressed(elements[i])
					if elements[i] then
						elements[i].buttonpressedhilight = 0.25
					end
				elseif elements[i].buttonpressedright and button == 2 then
					elements[i].buttonpressedright(elements[i])
					if elements[i] then
						elements[i].buttonpressedhilight = 0.25
					end
				end
				pressed = true
			end
		end
	end
	return pressed
end

---
--- Layout
---

--- layout.mouseOver
--- Returns true if the mouse is over any currently
--- displayed layouts
function layout.mouseOver()
	local mx, my = love.mouse.getPosition()
	for i = 1, # elements do
		local e = elements[i]
		if not e.dontblockmouse and not e.disabled and e.width and e.height and mx >= e.x and mx <= e.x + e.width and my >= e.y and my <= e.y + e.height then
			return true 
		end
	end
	return false
end

--- layout.updateBar
--- Updates progress bars.  Make them visually appealing :)
function layout.updateBar(e, dt)
	if e.prevval > e.minval then
		e.timer = e.timer - dt 
		if e.timer <= 0 then
			e.prevval = e.prevval - 25 * dt 
			if e.prevval <= e.minval then
				e.prevval = e.minval 
			end
		end
	else
		e.prevval = e.minval
		e.timer = 0.75
	end
end

--- layout.remove
--- Removes element of passed name
function layout.remove(name)
	for i = 1, # elements do
		if elements[i].name == name then
			table.remove(elements, i)
			break 
		end
	end
end

--- layout.setConstant
--- Sets element of passed name to be a constant
function layout.setConstant(name)
	for i = 1, # elements do
		if elements[i].name == name then
			elements[i].constant = true 
		end
	end
end

--- layout.clear
--- Removes all layout elements, and only removes
--- constant elements when const is passed true
function layout.clear(const)
	for i = # elements, 1, -1 do
		if elements[i].constant and const then
			table.remove(elements, i)
		elseif not elements[i].constant then
			table.remove(elements, i)
		end
	end
end

--- layout.drawSlider
function layout.drawSlider(e)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setLineWidth(6)
	love.graphics.line(e.x, e.y, e.x + e.width, e.y)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.setLineWidth(3)
	love.graphics.line(e.x, e.y, e.x + e.width, e.y)
	love.graphics.setLineWidth(1)
	love.graphics.rectangle('fill', e.x - 3, e.y - 6, 6, 12)
	love.graphics.rectangle('fill', e.x + e.width - 3, e.y - 6, 6, 12)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle('line', e.x - 3, e.y - 6, 6, 12)
	love.graphics.rectangle('line', e.x + e.width - 3, e.y - 6, 6, 12)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.circle('fill', e.x + (e.startval / e.maxval) * e.width, e.y, 7)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.circle('line', e.x + (e.startval / e.maxval) * e.width, e.y, 7)
end

--- layout.drawLine
--- Draws a line
function layout.drawLine(e)
	love.graphics.setColor(e.color[1], e.color[2], e.color[3], e.fade or e.color[4])
	love.graphics.setLineWidth(e.width)
	love.graphics.line(e.x1, e.y1, e.x2, e.y2)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setLineWidth(1)
end

--- layout.drawImg
--- Draws an image
function layout.drawImg(e)
	if e.shader and (not e.fade or e.fade >= 255) then
		love.graphics.setShader(shaders[e.shader].shader)
	end
	if e.fade and e.fade < 255 then
		shaders.fade.shader:send('a', e.fade / 255)
		--love.graphics.setShader(shaders.fade.shader)
		love.graphics.setColor(255, 255, 255, e.fade)
	end
	love.graphics.draw(e.img, e.x, e.y, e.rot, e.sx, e.sy)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setShader()
end

--- layout.drawFrame
--- Draws a blank frame
function layout.drawFrame(e)
	if e.fade and e.fade < 255 then
		shaders.fade.shader:send('a', e.fade / 255)
		love.graphics.setShader(shaders.fade.shader)
	end
	love.graphics.setColor(0, 0, 0, e.alpha)
	love.graphics.rectangle('fill', e.x, e.y, e.width, e.height)
	love.graphics.setColor(255, 255, 255, e.alpha)
	for x = 1, math.floor(e.width / 8) do
		love.graphics.draw(styles[e.style].edge, e.x + (x - 1) * 8, e.y)
		love.graphics.draw(styles[e.style].edge, e.x + (x - 1) * 8 + 8, e.y + e.height, math.pi)
	end
	for y = 1, math.floor(e.height / 8) do
		love.graphics.draw(styles[e.style].edge, e.x, e.y + (y - 1) * 8 + 8, 3 * math.pi / 2)
		love.graphics.draw(styles[e.style].edge, e.x + e.width, e.y + (y - 1) * 8, math.pi / 2)
	end
	love.graphics.draw(styles[e.style].corner, e.x, e.y)
	love.graphics.draw(styles[e.style].corner, e.x + e.width, e.y, math.pi / 2)
	love.graphics.draw(styles[e.style].corner, e.x, e.y + e.height, 3 * math.pi / 2)
	love.graphics.draw(styles[e.style].corner, e.x + e.width, e.y + e.height, math.pi)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setShader()
end

--- layout.drawBar
--- Draws a progress bar,
function layout.drawBar(e)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle('fill', e.x, e.y, e.width, e.height)
	if e.shader and (not e.fade or e.fade >= 255) then
		love.graphics.setShader(shaders[e.shader].shader)
	end
	if e.fade and e.fade < 255 then
		shaders.fade.shader:send('a', e.fade / 255)
		love.graphics.setShader(shaders.fade.shader)
	end
	love.graphics.setColor(e.losscolor[1], e.losscolor[2], e.losscolor[3], e.losscolor[4])
	love.graphics.rectangle('fill', e.x + e.width * (e.minval / e.maxval), e.y, (e.x + e.width * (e.prevval / e.maxval)) - (e.x + e.width * (e.minval / e.maxval)), e.height)
	love.graphics.setColor(e.color[1], e.color[2], e.color[3], e.color[4])
	love.graphics.rectangle('fill', e.x, e.y, e.width * (e.minval / e.maxval), e.height)
	love.graphics.setShader()
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle('line', e.x, e.y, e.width, e.height)
	love.graphics.setColor(150, 150, 150, 255)
	love.graphics.setLineWidth(1)
	love.graphics.rectangle('line', e.x + 2, e.y + 2, e.width - 4, e.height - 4)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setShader()
end

--- layout.drawButton
--- Draws a clickable button.
function layout.drawButton(e)
	if e.shader and (not e.fade or e.fade >= 255) then
		love.graphics.setShader(shaders[e.shader].shader)
	end
	if e.fade and e.fade < 255 then
		shaders.fade.shader:send('a', e.fade / 255)
		love.graphics.setShader(shaders.fade.shader)
	end
	love.graphics.draw(e.img, e.x, e.y, e.rot, e.sx, e.sy)
	love.graphics.setShader()
	if e.toggled then
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.rectangle('line', e.x, e.y, e.width, e.height)
		love.graphics.setColor(255, 255, 255, 100)
		love.graphics.rectangle('fill', e.x, e.y, e.width, e.height)
		love.graphics.setColor(255, 255, 255, 255)
	end
	if not e.pressable then
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.rectangle('line', e.x, e.y, e.width, e.height)
		love.graphics.setColor(0, 0, 0, 150)
		love.graphics.rectangle('fill', e.x, e.y, e.width, e.height)
		love.graphics.setColor(255, 255, 255, 255)
	end
	if e.buttonpressedhilight > 0 then
		love.graphics.setColor(100, 100, 100, 150)
		love.graphics.rectangle('fill', e.x, e.y, e.width, e.height)
		love.graphics.setColor(255, 255, 255, 255)
	end
end

--- layout.drawText
--- Draws a text display
function layout.drawText(e)
	love.graphics.setColor(e.color[1], e.color[2], e.color[3], e.fade or e.color[4])
	love.graphics.setFont(fonts[e.font])
	love.graphics.print(e.text, e.x, e.y, 0, e.zoom, e.zoom)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setShader()
end

--- layout.addText
--- Adds a text dispaly
function layout.addText(args)
	local e = {
		type = 'text',
		name = args.name or tostring(love.math.random(1111, 9999)),
		text = args.text or 'lorum ipsum',
		group = args.group or false,
		font = args.font or 'font1',
		color = args.color or {255, 255, 255, 255},
		x = args.x or 10,
		y = args.y or 10,
		z = args.z or 10,
		zoom = args.zoom or 1,
		constant = args.constant or false,
		disabled = args.disabled or false,
		dontblockmouse = args.dontblockmouse or false,
	}
	layout.addElement(e)
end

--- layout.addButton
--- Adds a clickable button.
function layout.addButton(args)
	local e = {
		type = 'button',
		name = args.name or tostring(love.math.random(1111, 9999)),
		img = args.img or love.graphics.newImage("img/layout/health.png"),
		x = args.x or 10,
		y = args.y or 10,
		z = args.z or 10,
		width = args.img:getWidth() or 32,
		height = args.img:getHeight() or 32,
		buttonpressed = args.buttonpressed or function () end,
		ontoggle = args.ontoggle or function () end,
		offtoggle = args.offtoggle or function () end,
		toggleable = args.toggleable or false,
		toggled = args.toggled or false,
		constant = args.constant or false,
		hilightable = args.hilightable or false,
		hilighttext = args.hilighttext or false,
		hilightfont = args.hilightfont or false,
		disabled = args.disabled or false,
		group = args.group or false,
		pressable = args.pressable or true,
		shader = args.shader or false,
		dontblockmouse = args.dontblockmouse or false,
		buttonpressedright = args.buttonpressedright or false,
		buttonpressedhilight = 0,
	}
	layout.addElement(e)
end

--- layout.addBar
--- Adds a progress bar, such as loading screens, health, mana...
function layout.addBar(args)
	local e = {
		type = 'bar',
		name = args.name or tostring(love.math.random(1111, 9999)),
		x = args.x or 10,
		y = args.y or 10,
		z = args.z or 10,
		width = args.width or 100,
		height = args.height or 15,
		minval = args.minval or 10,
		maxval = args.maxval or 20,
		prevval = args.minval or 10,
		timer = 0,
		color = args.color or {100, 100, 250, 255},
		bgcolor = args.color or {0, 0, 0, 255},
		losscolor = args.losscolor or {223, 113, 38, 255},
		constant = args.constant or false,
		hilightable = args.hilightable or false,
		hilighttext = args.hilighttext or false,
		hilightfont = args.hilightfont or false,
		disabled = args.disabled or false,
		group = args.group or false,
		shader = args.shader or false,
		dontblockmouse = args.dontblockmouse or false,
	}
	layout.addElement(e)
end

--- layout.addImage
--- Adds an image to be displayed
function layout.addImage(args)
	local e = {
		type = 'img',
		name = args.name or tostring(love.math.random(1111, 9999)), 
		img = args.img or love.graphics.newImage("img/layout/health.png"),
		x = args.x or 10,
		y = args.y or 10, 
		z = args.z or 10,
		width = args.img:getWidth() or 30,
		height = args.img:getHeight() or 30,
		rot = args.rot or 0,
		sx = args.sx or 1,
		sy = args.sy or 1,
		hilightable = args.hilightable or false,
		hilighttext = args.hilighttext or false,
		hilightfont = args.hilightfont or false,
		constant = args.constant or false,
		disabled = args.disabled or false,
		group = args.group or false,
		shader = args.shader or false,
		dontblockmouse = args.dontblockmouse or false,
		shadercolor = args.shadercolor or {255, 255, 255, 255},
		fade = args.fade or 255,
	}
	layout.addElement(e)
end

--- layout.addLine
function layout.addLine(args)
	local e = {
		type = 'line',
		name = args.name or tostring(love.math.random(1111, 9999)), 
		x1 = args.x1 or 10,
		y1 = args.y1 or 10,
		x2 = args.x2 or 50,
		y2 = args.y2 or 10,
		z = args.z or 10,
		color = args.color or {255, 255, 255, 255},
		width = args.width or 1,
		constant = args.constant or false,
		disabled = args.disabled or false,
		group = args.group or false,
		alpha = args.alpha or 255,
		fade = args.fade or 255,
	}
	layout.addElement(e)
end

--- layout.addSlider
function layout.addSlider(args)
	local e = {
		type = 'slider',
		name = args.name or tostring(love.math.random(1111, 9999)),
		x = args.x or 10,
		y = args.y or 10,
		z = args.z or 10,
		width = args.width or 100,
		minval = args.minval or 0,
		maxval = args.maxval or 100,
		startval = args.startval or 50,
		constant = args.constant or false,
		disabled = args.disabled or false,
		group = args.group or false,
	}
	layout.addElement(e)
end

--- layout.addFrame
--- Adds a blank frame used to visually build
--- other layout elements.  Style(int) determines
--- visual style, hilightable(boolean) hilights 
--- the frame on mouseover if true
function layout.addFrame(args)
	local e = {
		type = 'frame',
		name = args.name or tostring(love.math.random(1111, 9999)), 
		style = args.style or 1,
		x = args.x or 10,
		y = args.y or 10,
		z = args.z or 10,
		width = args.width or 100,
		height = args.height or 100,
		hilightable = args.hilightable or false,
		hilighttext = args.hilighttext or false,
		hilightfont = args.hilightfont or false,
		constant = args.constant or false,
		disabled = args.disabled or false,
		group = args.group or false,
		dontblockmouse = args.dontblockmouse or false,
		buttonpressed = args.buttonpressed or false,
		alpha = args.alpha or 255,
		flags = args.flags or 255,
	}
	layout.addElement(e)
end

--- layout.addElement
--- Adds the passed element to the elements table
--- sorted by element.z(int) in ascending order.
function layout.addElement(element)
	if not element.fade then element.fade = 255 end
	if # elements == 0 then
		table.insert(elements, element)
	else
		for i = 1, # elements + 1 do
			local z = 100
			if elements[i] then z = elements[i].z end
			if element.z <= z then
				table.insert(elements, i, element)
				break
			end
		end
	end
end

--- layout.executeFunction
--- Executes function held in passed index in the
--- name of the passed table.  Returns true if
--- succesful, false if the function or element
--- does not exist.
function layout.executeFunction(name, func)
	for i = 1, # elements do
		if elements[i].name == name and elements[i][func] then
			if type(elements[i][func]) == 'function' then
				elements[i][func](elements[i])
				return true 
			else
				return false 
			end
		end
	end
	return false
end

--- layout.getValue
--- Gets the value of table index passed in from
--- passed name element.  Returns false if one or
--- the other doesn't exist.
function layout.getValue(name, index)
	for i = 1, # elements do
		if elements[i].name == name and elements[i][index] then
			return elements[i][index]
		end
	end
	return false
end

--- layout.changeElementGroup
--- Changes the passed val by passed amount on all
--- elements belonging to passed group.  When modifyby
--- is passed the val is modified, not replaced
function layout.changeElementGroup(group, val, amnt, modifyby)
	for i = 1, # elements do
		if elements[i].group and elements[i].group == group then
			if not modifyby then
				elements[i][val] = amnt
			else
				if not elements[i][val] then elements[i][val] = amnt end
				elements[i][val] = elements[i][val] + amnt
			end
			if val == 'fade' and elements[i][val] > 245 then
				elements[i][val] = 255
			end
		end
	end
end

--- layout.changeElement
--- Changes the passed val by passed amount on
--- named element.  When modify is passed the val is
--- modified by amnt, not replace
function layout.changeElement(name, val, amnt, modifyby)
	for i = 1, # elements do
		if elements[i].name == name then
			if not modifyby then
				elements[i][val] = amnt
			else
				elements[i][val] = elements[i][val] + amnt
			end
			if val == 'fade' and elements[i][val] > 245 then
				elements[i][val] = 255
			end
			break 
		end
	end
end

--- layout.deleteFlaggedGroups
--- Deletes an entire group of layouts
function layout.deleteFlaggedGroups()
	local groups = groupsToDelete
	for k = 1, # groups do
		for i = # elements, 1, -1 do
			if elements[i].group == groups[k] then
				table.remove(elements, i)
			end
		end
	end
	groupsToDelete = { }
end

--- layout.deleteByGroup
--- Deletes an entire group of layouts
function layout.deleteByGroup(group)
	local toadd = true
	for i = 1, # groupsToDelete do
		if groupsToDelete[i] == group then
			toadd = false 
			break 
		end
	end
	if toadd then
		table.insert(groupsToDelete, group)
	end
end

--- layout.getTextWidth
--- Gets the width of text for passed font
function layout.getTextWidth(text, font)
	return fonts[font]:getWidth(text)
end

---
--- Getters/Setters
---

function layout.getFont(font)
	return fonts[font]
end

function layout.getElementByName(name) 
	for i = 1, # elements do 
		if elements[i].name == name then 
			return elements[i]
		end
	end
	return false 
end

function layout.getHilightedElement() return hilightedElement end

ScarletLib.layout = layout

return ScarletLib