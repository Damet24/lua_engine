local definitions = {
	terrain = {
		type = "image",
		path = "game/assets/images/Terrain/Terrain (16x16).png",
	},
	player_idle = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Idle (32x32).png",
	},
	player_run = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Run (32x32).png",
	},
	player_jump = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Jump (32x32).png",
	},
	player_double_jump = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Double Jump (32x32).png",
	},
	player_fall = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Fall (32x32).png",
	},
	player_wall_jump = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Wall Jump (32x32).png",
	},
	player_hit = {
		type = "image",
		path = "game/assets/images/Main Characters/Pink Man/Hit (32x32).png",
	},
	pause_font = {
		type = "font",
		size = 18,
	},
	background_blue = {
		type = "image",
		path = "game/assets/images/Background/Blue.png",
	},
	background_yellow = {
		type = "image",
		path = "game/assets/images/Background/Yellow.png",
	}
}

local function addImages(directory, images)
	for id, filename in pairs(images) do
		assert(not definitions[id], "duplicate resource id: " .. id)
		definitions[id] = { type = "image", path = "game/assets/images/" .. directory .. filename }
	end
end

addImages("", {
	enemies_preview = "20 Enemies.png",
	hello = "Hello.png",
})

addImages("Background/", {
	background_brown = "Brown.png",
	background_gray = "Gray.png",
	background_green = "Green.png",
	background_pink = "Pink.png",
	background_purple = "Purple.png",
})

addImages("Items/Boxes/", {
	box1_break = "Box1/Break.png", box1_hit = "Box1/Hit (28x24).png", box1_idle = "Box1/Idle.png",
	box2_break = "Box2/Break.png", box2_hit = "Box2/Hit (28x24).png", box2_idle = "Box2/Idle.png",
	box3_break = "Box3/Break.png", box3_hit = "Box3/Hit (28x24).png", box3_idle = "Box3/Idle.png",
})

addImages("Items/Checkpoints/", {
	checkpoint_flag_idle = "Checkpoint/Checkpoint (Flag Idle)(64x64).png",
	checkpoint_flag_out = "Checkpoint/Checkpoint (Flag Out) (64x64).png",
	checkpoint_no_flag = "Checkpoint/Checkpoint (No Flag).png",
	checkpoint_end_idle = "End/End (Idle).png",
	checkpoint_end_pressed = "End/End (Pressed) (64x64).png",
	checkpoint_start_idle = "Start/Start (Idle).png",
	checkpoint_start_moving = "Start/Start (Moving) (64x64).png",
})

addImages("Items/Fruits/", {
	fruit_apple = "Apple.png", fruit_bananas = "Bananas.png", fruit_cherries = "Cherries.png",
	fruit_collected = "Collected.png", fruit_kiwi = "Kiwi.png", fruit_melon = "Melon.png",
	fruit_orange = "Orange.png", fruit_pineapple = "Pineapple.png", fruit_strawberry = "Strawberry.png",
})

addImages("Main Characters/", {
	character_appearing = "Appearing (96x96).png",
	character_disappearing = "Desappearing (96x96).png",
})

addImages("Main Characters/Mask Dude/", {
	mask_dude_idle = "Idle (32x32).png", mask_dude_run = "Run (32x32).png",
	mask_dude_jump = "Jump (32x32).png", mask_dude_double_jump = "Double Jump (32x32).png",
	mask_dude_fall = "Fall (32x32).png", mask_dude_wall_jump = "Wall Jump (32x32).png",
	mask_dude_hit = "Hit (32x32).png",
})

addImages("Main Characters/Ninja Frog/", {
	ninja_frog_idle = "Idle (32x32).png", ninja_frog_run = "Run (32x32).png",
	ninja_frog_jump = "Jump (32x32).png", ninja_frog_double_jump = "Double Jump (32x32).png",
	ninja_frog_fall = "Fall (32x32).png", ninja_frog_wall_jump = "Wall Jump (32x32).png",
	ninja_frog_hit = "Hit (32x32).png",
})

addImages("Main Characters/Virtual Guy/", {
	virtual_guy_idle = "Idle (32x32).png", virtual_guy_run = "Run (32x32).png",
	virtual_guy_jump = "Jump (32x32).png", virtual_guy_double_jump = "Double Jump (32x32).png",
	virtual_guy_fall = "Fall (32x32).png", virtual_guy_wall_jump = "Wall Jump (32x32).png",
	virtual_guy_hit = "Hit (32x32).png",
})

addImages("Menu/Buttons/", {
	menu_button_achievements = "Achievements.png", menu_button_back = "Back.png",
	menu_button_close = "Close.png", menu_button_leaderboard = "Leaderboard.png",
	menu_button_levels = "Levels.png", menu_button_next = "Next.png", menu_button_play = "Play.png",
	menu_button_previous = "Previous.png", menu_button_restart = "Restart.png",
	menu_button_settings = "Settings.png", menu_button_volume = "Volume.png",
})

for level = 1, 50 do
	local number = string.format("%02d", level)
	addImages("Menu/Levels/", { ["menu_level_" .. number] = number .. ".png" })
end

addImages("Menu/Text/", {
	menu_text_black = "Text (Black) (8x10).png",
	menu_text_white = "Text (White) (8x10).png",
})

addImages("Other/", {
	confetti = "Confetti (16x16).png", dust_particle = "Dust Particle.png",
	shadow = "Shadow.png", transition = "Transition.png",
})

addImages("Traps/", {
	trap_arrow_hit = "Arrow/Hit (18x18).png", trap_arrow_idle = "Arrow/Idle (18x18).png",
	trap_blocks_hit_side = "Blocks/HitSide (22x22).png", trap_blocks_hit_top = "Blocks/HitTop (22x22).png",
	trap_blocks_idle = "Blocks/Idle.png", trap_blocks_part_1 = "Blocks/Part 1 (22x22).png",
	trap_blocks_part_2 = "Blocks/Part 2 (22x22).png",
	trap_falling_platform_off = "Falling Platforms/Off.png",
	trap_falling_platform_on = "Falling Platforms/On (32x10).png",
	trap_fan_off = "Fan/Off.png", trap_fan_on = "Fan/On (24x8).png",
	trap_fire_hit = "Fire/Hit (16x32).png", trap_fire_off = "Fire/Off.png", trap_fire_on = "Fire/On (16x32).png",
	trap_platform_brown_off = "Platforms/Brown Off.png", trap_platform_brown_on = "Platforms/Brown On (32x8).png",
	trap_platform_chain = "Platforms/Chain.png", trap_platform_grey_off = "Platforms/Grey Off.png",
	trap_platform_grey_on = "Platforms/Grey On (32x8).png",
	trap_rock_head_blink = "Rock Head/Blink (42x42).png", trap_rock_head_bottom_hit = "Rock Head/Bottom Hit (42x42).png",
	trap_rock_head_idle = "Rock Head/Idle.png", trap_rock_head_left_hit = "Rock Head/Left Hit (42x42).png",
	trap_rock_head_right_hit = "Rock Head/Right Hit (42x42).png", trap_rock_head_top_hit = "Rock Head/Top Hit (42x42).png",
	trap_ice_particle = "Sand Mud Ice/Ice Particle.png", trap_mud_particle = "Sand Mud Ice/Mud Particle.png",
	trap_sand_mud_ice = "Sand Mud Ice/Sand Mud Ice (16x6).png", trap_sand_particle = "Sand Mud Ice/Sand Particle.png",
	trap_saw_chain = "Saw/Chain.png", trap_saw_off = "Saw/Off.png", trap_saw_on = "Saw/On (38x38).png",
	trap_spiked_ball_chain = "Spiked Ball/Chain.png", trap_spiked_ball = "Spiked Ball/Spiked Ball.png",
	trap_spike_head_blink = "Spike Head/Blink (54x52).png", trap_spike_head_bottom_hit = "Spike Head/Bottom Hit (54x52).png",
	trap_spike_head_idle = "Spike Head/Idle.png", trap_spike_head_left_hit = "Spike Head/Left Hit (54x52).png",
	trap_spike_head_right_hit = "Spike Head/Right Hit (54x52).png", trap_spike_head_top_hit = "Spike Head/Top Hit (54x52).png",
	trap_spikes_idle = "Spikes/Idle.png", trap_trampoline_idle = "Trampoline/Idle.png",
	trap_trampoline_jump = "Trampoline/Jump (28x28).png",
})

return definitions
