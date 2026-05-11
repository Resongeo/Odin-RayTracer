package main

import "core:math/rand"

Lambertian :: struct {
    albedo: Vec3,
}

Metal :: struct {
    albedo: Vec3,
}

Glass :: struct {
    albedo: Vec3,
}

Material :: union {
    Lambertian,
    Metal,
    Glass,
}

material_scatter :: proc(material: Material, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    #partial switch m in material {
        case Lambertian: {
            return lambertian_scatter(m, r, hit, attenuation, scattered)
        }
        case Metal: {
            return metal_scatter(m, r, hit, attenuation, scattered)
        }
    }

    return false;
}

lambertian_scatter :: proc(m: Lambertian, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    target := hit.p + hit.normal + random_in_unit_sphere()
    scattered.a = hit.p
    scattered.b = target-hit.p
    attenuation.r = m.albedo.r
    attenuation.g = m.albedo.g
    attenuation.b = m.albedo.b

    return true;
}


metal_scatter :: proc(m: Metal, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    reflected := reflect(vec3_unit_vec(ray_direction(r)), hit.normal)
    scattered.a = hit.p
    scattered.b = reflected
    attenuation.r = m.albedo.r
    attenuation.g = m.albedo.g
    attenuation.b = m.albedo.b

    return (vec3_dot(ray_direction(scattered^), hit.normal) > 0)
}

new_material :: proc(M: $T) -> ^Material {
    mat := new(Material)
    mat^ = M

    return mat
}

@(private="file")
random_in_unit_sphere :: proc() -> Vec3 {
    p: Vec3

    for {
        p = 2*Vec3{rand.float32(), rand.float32(), rand.float32()} - Vec3{1, 1, 1}

        if vec3_squared_len(p) >= 1 {
            break
        }
    }

    return p
}

@(private="file")
reflect :: proc(v, n: Vec3) -> Vec3 {
    return v - 2*vec3_dot(v, n)*n
}