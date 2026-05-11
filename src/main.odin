package main

import "core:strconv"
import "core:os"
import "core:math"
import "core:c"
import "core:image"
import "core:log"
import "core:math/rand"
import stbi "vendor:stb/image"

IMAGE_NAME :: "output.png"

Options :: struct {
    width:   int,
    height:  int,
    samples: int,
}

main :: proc() {
    context.logger = log.create_console_logger()

    width := strconv.parse_int(os.args[1]) or_else 400
    height := strconv.parse_int(os.args[2]) or_else 200
    samples := strconv.parse_int(os.args[3]) or_else 16

    opt: Options = {
        width,
        height,
        samples,
    }

    log.infof("Rendering image\n\tWidth: %d\n\tHeight: %d\n\tSamples: %d", opt.width, opt.height, opt.samples)

    pixels: []image.RGB_Pixel = make([]image.RGB_Pixel, opt.width * opt.height)

    origin: Vec3 = {2, 1, 1}
    look_at: Vec3 = {0, 0, -1.6}
    focus_dist := vec3_len(origin - look_at)
    aperture:f32 = 0.2
    camera := new_camera(origin, look_at, 40, f32(opt.width)/f32(opt.height), aperture, focus_dist)

    world: World
    append(&world.spheres, Sphere{
        center = Vec3{0, 0, -1.6},
        radius = 0.5,
        material = new_material(Lambertian{
            albedo = Vec3{0.1, 0.2, 0.5}
        })
    })
    append(&world.spheres, Sphere{
        center = Vec3{1, 0, -1.5},
        radius = 0.5,
        material = new_material(Metal{
            albedo = Vec3{0.8, 0.3, 0.3},
            roughness = 0.8,
        })
    })
    append(&world.spheres, Sphere{
        center = Vec3{-1, 0, -1.5},
        radius = 0.5,
        material = new_material(Metal{
            albedo = Vec3{0.8, 0.6, 0.2},
            roughness = 0.25,
        })
    })
    append(&world.spheres, Sphere{
        center = Vec3{.4, -.2, -.8},
        radius = 0.2,
        material = new_material(Dielectric{
            ref_idx = 1.5
        })
    })
    append(&world.spheres, Sphere{
        center = Vec3{0, -1000.5, -1},
        radius = 1000,
        material = new_material(Lambertian{
            albedo = Vec3{0.5, 0.5, 0.5},
        })
    })

    total_pixels := opt.width * opt.height
    i := 0
    for y := opt.height - 1; y >= 0; y -= 1 {
        for x := 0; x < opt.width; x += 1 {
            col: Vec3

            for _ in 0..<opt.samples {
                u := (f32(x) + rand.float32()) / f32(opt.width)
                v := (f32(y) + rand.float32()) / f32(opt.height)
                
                r := camera_get_ray(camera, u, v)
                p := ray_point_at_parameter(r, 2)
                col += color(r, world, 0)
            }

            col /= f32(opt.samples)
            col = Vec3{
                math.sqrt_f32(col.r),
                math.sqrt_f32(col.g),
                math.sqrt_f32(col.b),
            }

            pixels[i] = vec3_to_rgb_pixel(col)
            i += 1
        }
    }

    img, ok := image.pixels_to_image(pixels[:], opt.width, opt.height)
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

