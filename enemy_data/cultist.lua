register_blueprint "cultist_self_destruct"
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

register_blueprint "cultist"
{
	blueprint = "zombie",
	lists = {
		group = "being",
		{ 1, keywords = { "io", "beyond", "former", "former3", "civilian" }, weight = 150 },
	},
	text  = {
		name  = "cultist",
		namep = "cultists",
	},
	callbacks = {
		on_create = [=[
		function( self, level )
		end
		]=],
		self_destruct = [=[
			function( self )
				if self:child("fanatic_attack") then
					world:destroy( self:child("fanatic_attack") )
					if self.health.current > 0 then	self.health.current = 1 end
					local w = world:create_entity( "cultist_self_destruct" )
					world:attach( self, w )
					world:get_level():fire( self, world:get_position( self ), w, 200 )
					local ar = area.around(world:get_position( self ), 1 )
					ar:clamp( world:get_level():get_area() )
					local c = generator.random_safe_spawn_coord( world:get_level(), ar, world:get_position( self ), 1 )
					local s  = world:get_level():add_entity( "reaver", c, nil )
					s.target.entity = world:get_player()
                    s.data.ai.state = "hunt"
					s.attributes.experience_value = 0
                    world:play_sound( "summon", s )
                    ui:spawn_fx( nil, "fx_summon", nil, world:get_position( s ) )
				end
			end
		]=],
		on_action = [=[
			function( self )
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
		]=],
		on_die = [=[
			function( self, killer, current, weapon )
				if self:child("fanatic_attack") then
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