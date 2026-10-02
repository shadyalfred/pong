package pong

import "core:math/rand"
import "core:mem"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 800
HEIGHT :: 600

Ball :: struct {
	position:        [2]f32,
	speed:           [2]f32,
	radius:          f32,
	collision_count: u32,
	color:           rl.Color,
}

Ripple :: struct {
	position: [2]f32,
	radius:   f32,
	alpha:    f32,
	color:    rl.Color,
}

main :: proc() {
	rl.InitWindow(WIDTH, HEIGHT, "pong")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	player_paddle := rl.Rectangle{WIDTH - 30, HEIGHT / 2 - 50, 20, 100}
	player_paddle_speed := f32(400.0)
	player_score := 0
	player_score_position := [2]i32{(WIDTH / 2 + WIDTH) / 2, 20}

	opponent_paddle := rl.Rectangle{30, HEIGHT / 2 - 50, 20, 100}
	opponent_paddle_speed := f32(400.0)
	opponent_score := 0
	opponent_score_position := [2]i32{WIDTH / 2 / 2, 20}

	COLORS := [?]rl.Color {
		rl.RED,
		rl.DARKGREEN,
		rl.YELLOW,
		rl.DARKBLUE,
		rl.PURPLE,
		rl.VIOLET,
		rl.MAGENTA,
	}

	SPEEDS := [?][2]f32 {
		[2]f32{100, 200},
		[2]f32{200, 400},
		[2]f32{200, 500},
		[2]f32{300, 200},
		[2]f32{300, 400},
		[2]f32{300, 500},
		[2]f32{400, 300},
		[2]f32{500, 400},
	}

	RADII := [?]f32{5, 8, 10, 12, 15, 18, 20, 22, 25, 30}

	balls := make_dynamic_array_len_cap([dynamic]Ball, 0, 64)
	append(&balls, Ball{[2]f32{WIDTH / 2, HEIGHT / 2}, [2]f32{300, 200}, 10, 0, rl.RED})

	ripples := make_dynamic_array_len_cap([dynamic]Ripple, 0, 64)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		if rl.IsKeyPressed(.ESCAPE) {
			break
		}

		if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
			player_paddle.y += player_paddle_speed * dt
		}
		if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
			player_paddle.y -= player_paddle_speed * dt
		}
		if player_paddle.y <= 0 {
			player_paddle.y = 0
		}
		if player_paddle.y + player_paddle.height >= HEIGHT {
			player_paddle.y = HEIGHT - player_paddle.height
		}

		opponent_paddle.y += opponent_paddle_speed * dt
		if opponent_paddle.y + opponent_paddle.height >= HEIGHT {
			opponent_paddle.y = HEIGHT - opponent_paddle.height
			opponent_paddle_speed = -opponent_paddle_speed
		}
		if opponent_paddle.y <= 0 {
			opponent_paddle.y = 0
			opponent_paddle_speed = -opponent_paddle_speed
		}

		for i := 0; i < len(balls); i += 1 {
			ball := &balls[i]

			if ball.speed.x > 0 &&
			   rl.CheckCollisionCircleRec(ball.position, ball.radius, player_paddle) {
				ball.collision_count += 1
				ball.position.x = player_paddle.x - ball.radius
				ball.speed.x = -ball.speed.x
			}
			if ball.speed.x < 0 &&
			   rl.CheckCollisionCircleRec(ball.position, ball.radius, opponent_paddle) {
				ball.collision_count += 1
				ball.position.x = opponent_paddle.x + opponent_paddle.width + ball.radius
				ball.speed.x = -ball.speed.x
			}

			ball.position.x += ball.speed.x * dt
			ball.position.y += ball.speed.y * dt
			if ball.position.x - ball.radius <= 0 {
				player_score += 1
				ball.position.x = ball.radius
				ball.speed.x = -ball.speed.x

				append(
					&ripples,
					Ripple {
						position = [2]f32{0, ball.position.y},
						radius = 0,
						alpha = 128,
						color = ball.color,
					},
				)
			}
			if ball.position.y - ball.radius <= 0 {
				ball.position.y = ball.radius
				ball.speed.y = -ball.speed.y
			}
			if ball.position.x + ball.radius >= WIDTH {
				opponent_score += 1
				ball.position.x = WIDTH - ball.radius
				ball.speed.x = -ball.speed.x

				append(
					&ripples,
					Ripple {
						position = [2]f32{WIDTH, ball.position.y},
						radius = 0,
						alpha = 128,
						color = ball.color,
					},
				)
			}
			if ball.position.y + ball.radius >= HEIGHT {
				ball.position.y = HEIGHT - ball.radius
				ball.speed.y = -ball.speed.y
			}

			if ball.collision_count == 5 {
				new_ball := Ball {
					position        = ball.position,
					speed           = rand.choice(SPEEDS[:]),
					radius          = rand.choice(RADII[:]),
					collision_count = 0,
					color           = rand.choice(COLORS[:]),
				}
				if ball.speed.x < 0 {
					new_ball.speed.x = -new_ball.speed.x
				}
				if ball.speed.y > 0 {
					new_ball.speed.y = -new_ball.speed.y
				}

				append(&balls, new_ball)
				ball.collision_count = 0
			}
		}

		for &ripple in ripples {
			ripple.radius += 400 * dt
			ripple.alpha -= 300 * dt
		}
		for i := len(ripples) - 1; i >= 0; i -= 1 {
			if ripples[i].alpha <= 0 {
				unordered_remove(&ripples, i)
			}
		}

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			for ripple in ripples {
				for i in 0 ..< 4 {
					radius := ripple.radius - f32(i) * 20
					if radius > 0 {
						color := ripple.color
						color.a = u8(max(0, ripple.alpha - f32(3 - i) * 30))

						rl.DrawCircleV(ripple.position, radius, color)
					}
				}
			}

			for ball in balls {
				rl.DrawCircleV(ball.position, ball.radius, ball.color)
			}

			rl.DrawRectangleRec(player_paddle, rl.WHITE)
			rl.DrawRectangleRec(opponent_paddle, rl.WHITE)

			rl.DrawText(
				itoa(player_score),
				player_score_position.x,
				player_score_position.y,
				20,
				rl.WHITE,
			)
			rl.DrawText(
				itoa(opponent_score),
				opponent_score_position.x,
				opponent_score_position.y,
				20,
				rl.WHITE,
			)

		}
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}

itoa :: proc(i: int, allocator: mem.Allocator = context.temp_allocator) -> cstring {
	buf: [16]byte
	s := auto_cast strconv.write_int(buf[:], auto_cast i, 10)
	cs, err := strings.clone_to_cstring(s, allocator)
	if err != nil {
		panic("error converting int to a cstring")
	}
	return cs
}
