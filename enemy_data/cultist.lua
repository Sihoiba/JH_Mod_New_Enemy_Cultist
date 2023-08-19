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
		local ar = area.around(world:get_position( self ), 1 )
		ar:clamp( world:get_level():get_area() )
		local c = generator.random_safe_spawn_coord( world:get_level(), ar, world:get_position( self ), 1 )
		local summon = self.data.killed_summon
		if self.data.suicide then
			summon = self.data.suicide_summon
		end
		local s  = world:get_level():add_entity( summon, c, nil )
		s.target.entity = world:get_player()
		s.data.ai.state = "hunt"
		s.attributes.experience_value = summon_xp
		world:play_sound( "summon", s )
		ui:spawn_fx( nil, "fx_summon", nil, world:get_position( s ) )	
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

register_blueprint "zealot_self_destruct"
{
	attributes = {
		damage    = 25,
		explosion = 3,
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
		damage    = 40,
		explosion = 3,
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
		explosion = 3,
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
		{ { "cultist", "cultist", "cult_sacrifice" }, keywords = { "test" }, weight = 150 },
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
					local ar = area.around(world:get_position( self ), 1 )
					ar:clamp( world:get_level():get_area() )
					for i = 1,5 do
						local c = generator.random_safe_spawn_coord( world:get_level(), ar, world:get_position( self ), 1 )				
						local s  = world:get_level():add_entity( "fiend", c, nil )
						s.target.entity = world:get_player()
						s.data.ai.state = "hunt"
						s.attributes.experience_value = summon_xp
						world:play_sound( "summon", s )
						ui:spawn_fx( nil, "fx_summon", nil, world:get_position( s ) )
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
		{ { "cult_leader", "cultist", "cultist", "cult_sacrifice" }, keywords = { "test" }, weight = 150 },			
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