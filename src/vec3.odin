package main

import "core:image"
import "core:math"

import "core:math/linalg/glsl"

Vec3 :: [3]f32

vec3_len :: proc(v: Vec3) -> f32 {
    return math.sqrt_f32(vec3_squared_len(v))
}

vec3_squared_len :: proc(v: Vec3) -> f32 {
    return v.x*v.x +
           v.y*v.y +
           v.z*v.z
}

vec3_unit_vec :: proc(v: Vec3) -> Vec3 {
    return v / vec3_len(v)
}

vec3_dot :: proc(v1, v2: Vec3) -> f32 {
    return v1.x*v2.x +
           v1.y*v2.y +
           v1.z*v2.z
}

vec3_cross :: proc(v1, v2: Vec3) -> Vec3 {
    return {
        v1.y*v2.z - v2.y*v1.z,
        v1.z*v2.x - v2.z*v1.x,
        v1.x*v2.y - v2.x*v1.y,
    }
}

vec3_to_rgb_pixel :: proc(v: Vec3) -> (pixel: image.RGB_Pixel) {
    return {
        u8(255*v.r),
        u8(255*v.g),
        u8(255*v.b),
    }
}
