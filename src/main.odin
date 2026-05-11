package main

import "core:text/regex/virtual_machine"
import "core:c"
import "core:fmt"
import "core:image"
import "core:log"
import stbi "vendor:stb/image"

IMAGE_WIDTH :: 1600
IMAGE_HEIGHT :: 800
IMAGE_NAME :: "output.png"

main :: proc() {
    context.logger = log.create_console_logger()
    pixels: []image.RGB_Pixel = make([]image.RGB_Pixel, IMAGE_WIDTH * IMAGE_HEIGHT)

    lower_left_corner := Vec3{-2, -1, -1}
    horizontal := Vec3{4, 0, 0}
    vertical := Vec3{0, 2, 0}
    origin := Vec3{0, 0, 0}

    i := 0
    for y := IMAGE_HEIGHT - 1; y >= 0; y -= 1 {
        for x := 0; x < IMAGE_WIDTH; x += 1 {
            u := f32(x) / f32(IMAGE_WIDTH)
            v := f32(y) / f32(IMAGE_HEIGHT)

            r := Ray{
                origin,
                lower_left_corner + u * horizontal + v * vertical
            }
            
            pixels[i] = vec3_to_rgb_pixel(color(r))
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

hit_sphere :: proc(center: Vec3, radius: f32, r: Ray) -> bool {
    oc := ray_origin(r) - center
    a := vec3_dot(ray_direction(r), ray_direction(r))
    b := 2 * vec3_dot(oc, ray_direction(r))
    c := vec3_dot(oc, oc) - radius * radius
    discriminant := b * b - 4 * a * c

    return discriminant > 0
}

color :: proc(r: Ray) -> Vec3 {
    if hit_sphere({0, 0, -1}, 0.5, r) {
        return {0.8, 0.3, 0.3}
    }

    unit_direction := vec3_unit_vec(ray_direction(r))
    t := 0.5 * (unit_direction.y + 1)
    return (1 - t) * Vec3{1, 1, 1} + t * Vec3{0.5, 0.7, 1.0}
}