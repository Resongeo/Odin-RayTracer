package main

import "core:math"
import "core:c"
import "core:image"
import "core:log"
import "core:math/rand"
import stbi "vendor:stb/image"

IMAGE_WIDTH :: 800
IMAGE_HEIGHT :: 400
IMAGE_NAME :: "output.png"
SAMPLES :: 16

main :: proc() {
    context.logger = log.create_console_logger()
    pixels: []image.RGB_Pixel = make([]image.RGB_Pixel, IMAGE_WIDTH * IMAGE_HEIGHT)

    camera := Camera {
        lower_left_corner = Vec3{-2, -1, -1},
        horizontal = Vec3{4, 0, 0},
        vertical = Vec3{0, 2, 0},
        origin = Vec3{0, 0, 0},
    }

    world: World
    append(&world.spheres, Sphere{center = Vec3{0, 0, -1}, radius = 0.5})
    append(&world.spheres, Sphere{center = Vec3{0, -100.5, -1}, radius = 100})

    i := 0
    for y := IMAGE_HEIGHT - 1; y >= 0; y -= 1 {
        for x := 0; x < IMAGE_WIDTH; x += 1 {
            col: Vec3

            for _ in 0..<SAMPLES {
                u := (f32(x) + rand.float32()) / f32(IMAGE_WIDTH)
                v := (f32(y) + rand.float32()) / f32(IMAGE_HEIGHT)
                
                r := camera_get_ray(camera, u, v)
                p := ray_point_at_parameter(r, 2)
                col += color(r, world)
            }

            col /= f32(SAMPLES)

            pixels[i] = vec3_to_rgb_pixel(col)
            i += 1
        }
    }

    img, ok := image.pixels_to_image(pixels[:], IMAGE_WIDTH, IMAGE_HEIGHT)
    if !ok {
        log.error("Failed to create image from pixels")
        return
    }

    ok = bool(
        stbi.write_png(
            IMAGE_NAME,
            c.int(img.width),
            c.int(img.height),
            c.int(img.channels),
            raw_data(img.pixels.buf[:]),
            c.int(img.width * img.channels),
        ),
    )
    if !ok {
        log.error("Failed to save {}", IMAGE_NAME)
    }
}

color :: proc(r: Ray, world: World) -> Vec3 {
    hit: Hit_Record

    if world_hit(world, r, 0, math.F32_MAX, &hit) {
        return 0.5*Vec3{
            hit.normal.x + 1,
            hit.normal.y + 1,
            hit.normal.z + 1,
        }
    }
    
    unit_direction := vec3_unit_vec(ray_direction(r))
    t := 0.5 * (unit_direction.y + 1)
    return (1 - t) * Vec3{1, 1, 1} + t * Vec3{0.5, 0.7, 1.0}
}