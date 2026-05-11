package main

import "core:math"

Hit_Record :: struct {
    t:        f32,
    p:        Vec3,
    normal:   Vec3,
    material: ^Material,
}

Sphere :: struct {
    center:   Vec3,
    radius:   f32,
    material: ^Material,
}

sphere_hit :: proc(s: Sphere, r: Ray, t_min, t_max: f32, hit: ^Hit_Record) -> bool {
    oc := ray_origin(r) - s.center
    a := vec3_dot(ray_direction(r), ray_direction(r))
    b := vec3_dot(oc, ray_direction(r))
    c := vec3_dot(oc, oc) -  s.radius*s.radius
    discriminant := b * b - a * c

    if discriminant > 0 {
        temp := (-b - math.sqrt_f32(b*b - a*c)) / a
        if temp < t_max && temp > t_min {
            hit.t = temp
            hit.p = ray_point_at_parameter(r, hit.t)
            hit.normal = (hit.p - s.center) / s.radius
            hit.material = s.material

            return true
        }

        temp = (-b + math.sqrt_f32(b*b - a*c)) / a
        if temp < t_max && temp > t_min {
            hit.t = temp
            hit.p = ray_point_at_parameter(r, hit.t)
            hit.normal = (hit.p - s.center) / s.radius
            hit.material = s.material

            return true
        }
    }

    return false
}