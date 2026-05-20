package main

import "base:runtime"
import "core:log"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:thread"

import rl "vendor:raylib"

Options :: struct {
	width:   i32,
	height:  i32,
	samples: i32,
}

Render_Task :: struct {
	y_start: int,
	y_end:   int,
	width:   int,
	height:  int,
	samples: int,
	pixels:  []rl.Color,
	camera:  ^Camera,
	world:   ^World,
}

main :: proc() {
	context.logger = log.create_console_logger()

	width := strconv.parse_int(os.args[1]) or_else 400
	height := strconv.parse_int(os.args[2]) or_else 200
	samples := strconv.parse_int(os.args[3]) or_else 16

	opt := Options {
		width   = i32(width),
		height  = i32(height),
		samples = i32(samples),
	}

	rl.SetTraceLogLevel(.ERROR)
	rl.InitWindow(opt.width, opt.height, "Raytracer")
	defer rl.CloseWindow()

	pixels := make([]rl.Color, opt.width * opt.height)

	image := rl.GenImageColor(opt.width, opt.height, rl.BLACK)
	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)
	defer rl.UnloadImage(image)

	origin := Vec3{13, 2, 3}
	look_at := Vec3{0, 0, 0}

	camera := new_camera(origin, look_at, 20, f32(opt.width) / f32(opt.height), 0.08, 10)

	world := new_random_world()

	core_count := os.get_processor_core_count() - 1
	if core_count < 1 do core_count = 1

	pool: thread.Pool
	thread.pool_init(&pool, context.allocator, core_count)
	thread.pool_start(&pool)
	defer thread.pool_destroy(&pool)

	rows_per_task := height / core_count

	y := 0
	for y < height {
		y_end := y + rows_per_task
		if y_end > height do y_end = height

		task := new(Render_Task)
		task.y_start = y
		task.y_end = y_end
		task.width = width
		task.height = height
		task.samples = samples
		task.pixels = pixels
		task.camera = &camera
		task.world = &world

		thread.pool_add_task(&pool, context.allocator, thread_work, task, y)

		y = y_end
	}

	update_interval := 1.0
	last_update_time := rl.GetTime()

	for !rl.WindowShouldClose() {
		current_time := rl.GetTime()

		if current_time - last_update_time >= update_interval || thread.pool_is_empty(&pool) {
			rl.UpdateTexture(texture, raw_data(pixels))
			last_update_time = current_time
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}

	thread.pool_finish(&pool)
}

thread_work :: proc(t: thread.Task) {
	task := cast(^Render_Task)t.data

	state := rand.create(u64(task.y_start + 1))
	context.random_generator = rand.default_random_generator(&state)

	for y := task.y_start; y < task.y_end; y += 1 {
		for x := 0; x < task.width; x += 1 {
			col: Vec3

			for _ in 0 ..< task.samples {
				u := (f32(x) + rand.float32()) / f32(task.width)
				v := (f32(y) + rand.float32()) / f32(task.height)

				r := camera_get_ray(task.camera^, u, v)
				col += color(r, task.world^, 0)
			}

			col /= f32(task.samples)

			// Gamma correction
			col = Vec3{math.sqrt_f32(col.r), math.sqrt_f32(col.g), math.sqrt_f32(col.b)}

			idx := (task.height - 1 - y) * task.width + x

			task.pixels[idx] = rl.Color {
				u8(255.99 * col.r),
				u8(255.99 * col.g),
				u8(255.99 * col.b),
				255,
			}
		}
	}

	free(task)
}

color :: proc(r: Ray, world: World, depth: int) -> Vec3 {
	hit: Hit_Record
	if world_hit(world, r, 0.001, math.F32_MAX, &hit) {
		scattered: Ray
		attenuation: Vec3

		if depth < 50 && material_scatter(hit.material^, r, hit, &attenuation, &scattered) {
			return attenuation * color(scattered, world, depth + 1)
		}

		return Vec3{0, 0, 0}
	}

	unit_direction := vec3_unit_vec(ray_direction(r))
	t := 0.5 * (unit_direction.y + 1)
	return (1 - t) * Vec3{1, 1, 1} + t * Vec3{0.5, 0.7, 1.0}
}
