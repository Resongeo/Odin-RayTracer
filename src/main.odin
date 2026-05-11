package main

import "core:strconv"
import "core:os"
import "core:math"
import "core:c"
import "core:image"
import "core:log"
import "core:math/rand"

import stbi "vendor:stb/image"
import rl "vendor:raylib"

IMAGE_NAME :: "output.png"

Options :: struct {
    width:   i32,
    height:  i32,
    samples: i32,
}

main :: proc() {
    context.logger = log.create_console_logger()

    width := strconv.parse_int(os.args[1]) or_else 400
    height := strconv.parse_int(os.args[2]) or_else 200
    samples := strconv.parse_int(os.args[3]) or_else 16

    opt := Options{
        width   = i32(width),
        height  = i32(height),
        samples = i32(samples),
    }

    rl.SetTraceLogLevel(.ERROR)
    rl.InitWindow(opt.width, opt.height, "Raytracer")
    defer rl.CloseWindow()

    pixels := make([]rl.Color, opt.width * opt.height)

    image := rl.GenImageColor(
        i32(opt.width),
        i32(opt.height),
        rl.BLACK,
    )

    texture := rl.LoadTextureFromImage(image)

    defer rl.UnloadTexture(texture)
    defer rl.UnloadImage(image)

    origin: Vec3 = {13, 2, 3}
    look_at: Vec3 = {0, 0, 0}

    focus_dist: f32 = 10
    aperture: f32 = 0.1

    camera := new_camera(
        origin,
        look_at,
        20,
        f32(opt.width)/f32(opt.height),
        aperture,
        focus_dist,
    )

    world := new_random_world()

    x: i32 = 0
    y: i32 = opt.height - 1

    done := false

    batch_size := opt.width * opt.height / 32

    for !rl.WindowShouldClose() {

        for _ in 0..<batch_size {
            if !done {
                col: Vec3

                for _ in 0..<opt.samples {
                    u := (f32(x) + rand.float32()) / f32(opt.width)
                    v := (f32(y) + rand.float32()) / f32(opt.height)

                    r := camera_get_ray(camera, u, v)

                    col += color(r, world, 0)
                }

                col /= f32(opt.samples)

                col = Vec3{
                    math.sqrt_f32(col.r),
                    math.sqrt_f32(col.g),
                    math.sqrt_f32(col.b),
                }

                idx := (opt.height - 1 - y) * opt.width + x

                pixels[idx] = rl.Color{
                    u8(255.99 * col.r),
                    u8(255.99 * col.g),
                    u8(255.99 * col.b),
                    255,
                }

                x += 1

                if x >= opt.width {
                    x = 0
                    y -= 1

                    if y < 0 {
                        done = true
                        log.info("Render complete")
                    }
                }
            }
        }

        rl.UpdateTexture(
            texture,
            raw_data(pixels),
        )

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawTexture(texture, 0, 0, rl.WHITE)

        rl.EndDrawing()
    }
}

color :: proc(r: Ray, world: World, depth: int) -> Vec3 {
    hit: Hit_Record

    if world_hit(world, r, 0.001, math.F32_MAX, &hit) {
        scattered: Ray
        attenuation: Vec3

        if depth < 50 && material_scatter(hit.material^, r, hit, &attenuation, &scattered) {
            return attenuation*color(scattered, world, depth+1)
        }
        
        return Vec3{0, 0, 0}
    }
    
    unit_direction := vec3_unit_vec(ray_direction(r))
    t := 0.5 * (unit_direction.y + 1)
    return (1 - t) * Vec3{1, 1, 1} + t * Vec3{0.5, 0.7, 1.0}
}

