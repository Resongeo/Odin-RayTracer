package main

import "core:math"
import "core:math/rand"

Camera :: struct {
    origin:            Vec3,
    vertical:          Vec3,
    horizontal:        Vec3,
    lower_left_corner: Vec3,
    u:                 Vec3,
    v:                 Vec3,
    w:                 Vec3,
    lens_radius:       f32,
}

new_camera :: proc(origin, look_at: Vec3, fov, aspect, aperture, focus_dist: f32) -> (camera: Camera) {
    theta := fov*f32(math.PI)/180.0
    half_height := math.tan_f32(theta/2)
    half_width := aspect*half_height
    
    camera.lens_radius = aperture / 2
    camera.w = vec3_unit_vec(origin - look_at)
    camera.u = vec3_unit_vec(vec3_cross(Vec3{0, 1, 0} /* Up vector */, camera.w))
    camera.v = vec3_cross(camera.w, camera.u)
    camera.lower_left_corner = origin - half_width*focus_dist*camera.u - half_height*focus_dist*camera.v - focus_dist*camera.w
    camera.horizontal = 2*half_width*focus_dist*camera.u
    camera.vertical = 2*half_height*focus_dist*camera.v
    camera.origin = origin

    return camera
}

camera_get_ray :: proc(camera: Camera, s, t: f32) -> Ray {
    rd := camera.lens_radius*random_in_unit_disk()
    offset := camera.u*rd.x + camera.v*rd.y

    return {
        camera.origin + offset,
        camera.lower_left_corner + s*camera.horizontal + t*camera.vertical - camera.origin - offset,
    }
}

@(private="file")
random_in_unit_disk :: proc() -> Vec3 {
    p: Vec3

    for {
        p = 2*Vec3{rand.float32(), rand.float32(), 0} - Vec3{1, 1, 0}

        if vec3_dot(p, p) < 1 {
            break
        }
    }

    return p
}