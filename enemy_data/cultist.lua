function cultist_safe_spawn_coord_spiral_out( self, start_coord, max_range )
	local max_range = max_range or 6
	
	local floor_id = self:get_nid( "floor" )
	local function can_spawn( p, c )
		if self:raw_get_cell( c ) ~= floor_id then return false end
		if self:get_cell_flags( c )[ EF_NOSPAWN ] then return false end
		if not p then return true end

		local pc = p - c
		if pc.x < 0 then pc.x = -pc.x end
		if pc.y < 0 then pc.y = -pc.y end
		return pc.x <= max_range or pc.y <= max_range
	end
	
	local function spiral_get_values(range)
		local cx = 0
		local cy = 0
		local d = 1
		local m = 1
		local spiral_coords = {}
		while cx <= range and cy <= range do
			while (2 * cx * d) < m do
				table.insert(spiral_coords, {x=cx, y=cy})
				cx = cx + d
			end
			while (2 * cy * d) < m do
				table.insert(spiral_coords, {x=cx, y=cy})
				cy = cy + d
			end
			d = -1 * d
			m = m + 1			
		end
		return spiral_coords
	end
	
	local p = start_coord
	if can_spawn( p, p ) then
		return p
	end
	
	local spawn_coords = spiral_get_values(max_range)
	for k,v in ipairs(spawn_coords) do
		p.x = start_coord.x + v.x
		p.y = start_coord.y + v.y
		nova.log("Checking "..tostring(p.x)..","..tostring(p.y))
		if can_spawn( start_coord, p ) then
			return p
		end
	end
end

function self_destruct_effect( self, destruct_type )
	if self:child("fanatic_attack") then
		world:destroy( self:child("fanatic_attack") )
		if self.health.current > 0 then	self.health.current = 1 end
		local w = world:create_entity( destruct_type )
		world:attach( self, w )
		world:get_level():fire( self, world:get_position( self ), w, 200 )
		self.data.summon = true
	end
end

function self_destruct_summon(self, summon_xp )
	if self.data.summon then
		nova.log(tostring(self).." is summoning on death")
		local c = cultist_safe_spawn_coord_spiral_out( world:get_level(), world:get_position( self ), 3 )
		
		if c then
			local summon = self.data.killed_summon
			if self.data.suicide then
				summon = self.data.suicide_summon
			end
			nova.log(tostring(self).." is summoning on death - safe spawn coords x:"..tostring(c.x)..", y:"..tostring(c.y))
			local s  = world:get_level():add_entity( summon, c, nil )
			s.target.entity = world:get_player()
			s.data.ai.state = "hunt"
			s.attributes.experience_value = summon_xp			
			world:add_buff( s, "buff_cult_summon", 200 )
			world:play_sound( "summon", s )
			ui:spawn_fx( nil, "fx_summon", nil, c )	
		else 
			nova.log(tostring(self).." no where safe to summon")
		end	
	end
end

function fanatic_action(self)
	local level    = world:get_level()
	local distance = 999
	if self.target and self.target.entity and self.target.entity == world:get_player() and level:can_see_entity( self, self.target.entity, 8 ) then
	distance = level:distance( self, self.target.entity )
		if distance < 6 and not self:child("fanatic_attack") then
			self:equip("fanatic_attack")
		end
	end
	aitk.standard_ai( self ) 
	if distance < 2 then
		world:lua_callback( self, "self_destruct" )
	end
end

register_blueprint "buff_cult_summon"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name    = "Summoned",
		desc    = "Briefly protects against splash damage and fire",
	},
	callbacks = {
		on_die = [[
			function ( self )
				world:mark_destroy( self )
			end
		]],
	},
	attributes = {
		splash_mod = 0.0,
		resist = {
            ignite = 200,
        },
	},
	ui_buff = {
		color = MAGENTA,
	},
}

register_blueprint "zealot_self_destruct"
{
	attributes = {
		damage    = 25,
		explosion = 2,
		gib_factor= 2,
	},
	weapon = {
		group = "env",
		damage_type = "slash",
		natural = true,
		fire_sound = "explosion",
	},
	noise = {
		use = 15,
	},
	callbacks = {
		on_create = [[
			function ( self )
				self.attributes.damage = self.attributes.damage + 10 * math.min( DIFFICULTY, 3 )
			end
		]],
		on_area_damage = [[
			function ( self, level, c, damage, distance, center, source )
				if center then 
					gtk.place_flames( c, 3, 400 )
				end
			end
		]],
	}
}

register_blueprint "cultist_self_destruct"
{
	attributes = {
		damage    = 30,
		explosion = 2,
		gib_factor= 2,
	},
	weapon = {
		group = "env",
		damage_type = "slash",
		natural = true,
		fire_sound = "explosion",
	},
	noise = {
		use = 15,
	},
	callbacks = {
		on_create = [[
			function ( self )
				self.attributes.damage = self.attributes.damage + 10 * math.min( DIFFICULTY, 3 )
			end
		]],
		on_area_damage = [[
			function ( self, level, c, damage, distance, center, source )
				if center then 
					gtk.place_flames( c, 3, 400 )
				end
			end
		]],
	}
}

register_blueprint "cultist_leader_self_destruct"
{
	attributes = {
		damage    = 40,
		explosion = 2,
		gib_factor= 2,
	},
	weapon = {
		group = "env",
		damage_type = "plasma",
		natural = true,
		fire_sound = "explosion",
	},
	noise = {
		use = 15,
	},
	callbacks = {
		on_create = [[
			function ( self )
				self.attributes.damage = self.attributes.damage + 10 * math.min( DIFFICULTY, 3 )
			end
		]],
		on_area_damage = [[
			function ( self, level, c, damage, distance, center, source )
				if center then 
					gtk.place_flames( c, 3, 400 )
				end
			end
		]],
	}
}

register_blueprint "zealot"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		{ keywords = { "test" }, weight = 150 },
		{ 1, keywords = { "europa", "former", "former2", "civilian" }, weight = 150 },
		{ 2, keywords = { "europa", "former", "former2", "civilian" }, weight = 50 },
		{ 4, keywords = { "europa", "former", "former2", "civilian" }, weight = 25, dmin = 12 },
	},
	text  = {
		name  = "zealot",
		namep = "zealots",
	},
	data = {
		suicide_summon = "ice_fiend",
		killed_summon = "fiend",
		suicide = true,
		summon = false,
	},
	callbacks = {
		on_create = [=[
		function( self, level )
		end
		]=],
		self_destruct = [=[
			function( self )
				self_destruct_effect( self, "zealot_self_destruct")
				self_destruct_summon( self, 30 )
			end
		]=],
		on_action = [=[
			function( self )
				fanatic_action(self)
			end
		]=],
		on_die = [=[
			function( self, killer, current, weapon )
				if self:child("fanatic_attack") then
					self.data.suicide = false
					world:lua_callback( self, "self_destruct" )
				end
			end
		]=],
	},
	attributes = {
		health   = 60,
		speed    = 1.0,
		accuracy = -40,
	},
}

register_blueprint "cultist"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		-- { keywords = { "test" }, weight = 150 },
		{ 1, keywords = { "io", "former", "former3", "civilian" }, weight = 150 },
		{ 2, keywords = { "io", "former", "former3", "civilian" }, weight = 50 },
	},
	text  = {
		name  = "cultist",
		namep = "cultists",
	},
	data = {
		suicide_summon = "cryoreaver",
		killed_summon = "reaver",
		suicide = true,
		summon = false,
	},
	callbacks = {
		on_create = [=[
		function( self, level )
		end
		]=],
		self_destruct = [=[
			function( self )
				self_destruct_effect( self, "cultist_self_destruct" )
				self_destruct_summon( self, 70 )
			end
		]=],
		on_action = [=[
			function( self )
				fanatic_action(self)
			end
		]=],
		on_die = [=[
			function( self, killer, current, weapon )
				if self:child("fanatic_attack") then
					self.data.suicide = false
					world:lua_callback( self, "self_destruct" )
				end
			end
		]=],
	},
	attributes = {
		health   = 75,
		speed    = 1.1,
		accuracy = -40,
	},
}

register_blueprint "cult_sacrifice"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		{ keywords = { "test" }, weight = 150 },
		-- { { "cultist", "cultist", "cult_sacrifice" }, keywords = { "test" }, weight = 150 },
		{ 1, keywords = { "io", "beyond", "former", "former3", "civilian" }, weight = 100 },
		{ { "cultist", "cultist", "cult_sacrifice" }, keywords = { "io", "beyond", "former", "former3", "civilian" }, weight = 50 },
	},
	text  = {
		name  = "cult sacrifice",
		namep = "cult sacrifice",
	},
	data = {
		summon = false,
	},
	callbacks = {
		on_create = [=[
		function( self, level )
		end
		]=],
		self_destruct = [=[
			function( self )				
				self_destruct_effect( self, "fanatic_self_destruct" )
				if self.data.summon then
					nova.log(tostring(self).." is summoning on death")
					for i = 1,5 do
						local c = cultist_safe_spawn_coord_spiral_out( world:get_level(), world:get_position( self ), 3 )
						
						if c then							
							nova.log(tostring(self).." is summoning on death - safe spawn coords x:"..tostring(c.x)..", y:"..tostring(c.y))
							local s  = world:get_level():add_entity( "fiend", c, nil )
							s.target.entity = world:get_player()
							s.data.ai.state = "hunt"
							s.attributes.experience_value = summon_xp			
							world:add_buff( s, "buff_cult_summon", 200 )
							world:play_sound( "summon", s )
							ui:spawn_fx( nil, "fx_summon", nil, c )	
						else 
							nova.log(tostring(self).." no where safe to summon")
						end
					end					
				end		
			end
		]=],
		on_action = [=[
			function( self )
				fanatic_action(self)
			end
		]=],
		on_die = [=[
			function( self, killer, current, weapon )
				if self:child("fanatic_attack") then
					self.data.suicide = false
					world:lua_callback( self, "self_destruct" )
				end
			end
		]=],
	},
	attributes = {
		health   = 25,
		speed    = 1.2,
		accuracy = -40,
	},
}

register_blueprint "cult_leader"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		-- { { "cult_leader", "cultist", "cultist", "cult_sacrifice" }, keywords = { "test" }, weight = 150 },			
		{ { "cult_leader", "cultist", "cultist" }, keywords = { "pack", "io", "beyond", "former", "former3", "civilian" }, weight = 250, dmin = 20 },
		{ { "cult_leader", "cultist", "cultist", "cult_sacrifice" }, keywords = { "pack", "io", "beyond", "former", "former3", "civilian" }, weight = 250, dmin = 21 },
		{ 1, keywords = { "io", "beyond", "former", "former3", "civilian" }, weight = 150 },
	},
	text  = {
		name  = "cult leader",
		namep = "cult leader",
	},
	data = {
		suicide_summon = "temple_guardian",
		killed_summon = "cryoreaver",
		suicide = true,
		summon = false,
	},
	callbacks = {
		on_create = [=[
		function( self, level )
		end
		]=],
		self_destruct = [=[
			function( self )
				self_destruct_effect( self, "cultist_leader_self_destruct" )
				self_destruct_summon( self, 90 )			
			end
		]=],
		on_action = [=[
			function( self )
				fanatic_action(self)
			end
		]=],
		on_die = [=[
			function( self, killer, current, weapon )
				if self:child("fanatic_attack") then
					self.data.suicide = false
					world:lua_callback( self, "self_destruct" )
				end
			end
		]=],
	},
	attributes = {
		health   = 90,
		speed    = 1.1,
		accuracy = -40,
	},
}