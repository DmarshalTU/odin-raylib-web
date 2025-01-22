package game
import rl "vendor:raylib"

Platform :: struct {
	position: rl.Vector2,
	width:    f32,
	active:   bool,
}

Collectible :: struct {
	position:  rl.Vector2,
	collected: bool,
	radius:    f32,
	color:     rl.Color,
}

player_run_texture: rl.Texture
base_texture: rl.Texture
player_position := rl.Vector2{640, 500} // Starting lower to ensure landing on platform
player_velocity: rl.Vector2
player_grounded: bool
player_flip: bool
player_run_num_frames := 4
player_run_frame_timer: f32
player_run_current_frame: int
player_run_frame_length := f32(0.1)
score := 0

// New game state variables
platforms: [10]Platform
collectibles: [15]Collectible
game_over: bool
DEBUG_DRAW := true

init :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Icy Tower Cat")
	player_run_texture = rl.LoadTexture("assets/cat_run.png")
	base_texture = rl.LoadTexture("assets/long_cat.png")

	reset_game()
}

reset_game :: proc() {
	// Reset player
	player_position = rl.Vector2{640, 500}
	player_velocity = rl.Vector2{0, 0}
	score = 0
	game_over = false

	// Create initial ground platform
	platforms[0] = Platform {
		position = rl.Vector2{640, 600}, // Ground platform
		width    = 800, // Wide platform as ground
		active   = true,
	}

	// Create other platforms
	for i := 1; i < 10; i += 1 {
		platforms[i] = Platform {
			position = rl.Vector2 {
				f32(300 + (i % 2) * 600), // Alternate between left and right
				f32(550 - i * 100), // Platforms going up (reduced spacing)
			},
			width    = 200,
			active   = true,
		}
	}

	// Create collectibles near platforms
	for i := 0; i < 15; i += 1 {
		platforms_idx := i % 9 // Match collectibles with platform positions
		collectibles[i] = Collectible {
			position  = rl.Vector2 {
				platforms[platforms_idx].position.x,
				platforms[platforms_idx].position.y - 50, // Place above platforms
			},
			collected = false,
			radius    = 10,
			color     = rl.YELLOW,
		}
	}
}

check_platform_collision :: proc() -> bool {
	for platform in platforms {
		if !platform.active do continue

		// Check if player is within the platform's x-bounds
		if player_position.x + 32 > platform.position.x - platform.width / 2 &&
		   player_position.x + 32 < platform.position.x + platform.width / 2 {

			// Check if player is landing on the platform
			if player_velocity.y > 0 &&
			   player_position.y + 64 >= platform.position.y - 10 &&
			   player_position.y + 64 <= platform.position.y + 10 {

				// Snap to platform
				player_position.y = platform.position.y - 64
				player_velocity.y = 0
				return true
			}
		}
	}
	return false
}

check_collectibles :: proc() {
	for collectible, idx in &collectibles {
		if collectible.collected do continue

		// Check collision with player
		player_center := rl.Vector2{player_position.x + 32, player_position.y + 32}

		if rl.CheckCollisionCircles(player_center, 32, collectible.position, collectible.radius) {
			collectibles[idx].collected = true
			score += 10
		}
	}
}

update :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground({110, 184, 168, 255})

	// Draw platforms
	for platform in platforms {
		if !platform.active do continue
		rl.DrawRectangleV(
			rl.Vector2{platform.position.x - platform.width / 2, platform.position.y},
			rl.Vector2{platform.width, 20},
			rl.DARKGRAY,
		)
	}

	// Draw collectibles
	for collectible in collectibles {
		if !collectible.collected {
			rl.DrawCircleV(collectible.position, collectible.radius, collectible.color)
		}
	}

	// Draw score
	score_text := rl.TextFormat("Score: %d", score)
	rl.DrawText(score_text, 10, 10, 20, rl.BLACK)

	// Draw restart button
	restart_btn_bounds := rl.Rectangle{10, 40, 100, 30}
	if rl.GuiButton(restart_btn_bounds, "Restart") {
		reset_game()
	}

	// Player movement
	if !game_over {
		if rl.IsKeyDown(.A) {
			player_velocity.x = -400
			player_flip = true
		} else if rl.IsKeyDown(.D) {
			player_velocity.x = 400
			player_flip = false
		} else {
			player_velocity.x *= 0.9 // Add some friction
		}

		player_velocity.y += 1500 * rl.GetFrameTime() // Reduced gravity

		if player_grounded && rl.IsKeyPressed(.W) {
			player_velocity.y = -850 // Increased jump power
			player_grounded = false
		}

		// Update position
		player_position += player_velocity * rl.GetFrameTime()

		// Screen wrapping
		if player_position.x > f32(rl.GetScreenWidth()) {
			player_position.x = 0
		} else if player_position.x < 0 {
			player_position.x = f32(rl.GetScreenWidth())
		}
	}

	// Check collisions
	player_grounded = check_platform_collision()
	check_collectibles()

	// Check if player fell off screen
	if player_position.y > f32(rl.GetScreenHeight()) {
		game_over = true
	}

	// Draw game over message
	if game_over {
		game_over_text := rl.TextFormat("Game Over!")
		text_width := rl.MeasureText(game_over_text, 40)
		rl.DrawText(
			game_over_text,
			i32(f32(rl.GetScreenWidth()) / 2 - f32(text_width) / 2),
			i32(f32(rl.GetScreenHeight()) / 2),
			40,
			rl.RED,
		)
	}

	// Draw player animation
	player_run_texture_width := f32(player_run_texture.width)
	player_run_texture_height := f32(player_run_texture.height)
	player_run_frame_timer += rl.GetFrameTime()
	if player_run_frame_timer > player_run_frame_length {
		player_run_current_frame += 1
		player_run_frame_timer = 0
		if player_run_current_frame == player_run_num_frames {
			player_run_current_frame = 0
		}
	}

	draw_player_source := rl.Rectangle {
		x      = f32(
			player_run_current_frame,
		) * player_run_texture_width / f32(player_run_num_frames),
		y      = 0,
		width  = player_run_texture_width / f32(player_run_num_frames),
		height = player_run_texture_height,
	}

	if player_flip {
		draw_player_source.width = -draw_player_source.width
	}

	draw_player_dest := rl.Rectangle {
		x      = player_position.x,
		y      = player_position.y,
		width  = player_run_texture_width * 4 / f32(player_run_num_frames),
		height = player_run_texture_height * 4,
	}

	rl.DrawTexturePro(player_run_texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)

	// Debug visualization
	if DEBUG_DRAW {
		for platform in platforms {
			if !platform.active do continue
			rl.DrawRectangleLines(
				i32(platform.position.x - platform.width / 2),
				i32(platform.position.y - 10),
				i32(platform.width),
				20,
				rl.RED,
			)
		}
		rl.DrawRectangleLines(i32(player_position.x), i32(player_position.y), 64, 64, rl.GREEN)
	}

	rl.EndDrawing()
	free_all(context.temp_allocator)
}

parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}

shutdown :: proc() {
	rl.CloseWindow()
}
