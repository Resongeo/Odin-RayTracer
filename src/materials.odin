package main

import "core:math"
import "core:math/rand"

Lambertian :: struct {
    albedo: Vec3,
}

Metal :: struct {
    albedo:    Vec3,
    roughness: f32,
}
Dielectric :: struct {
    ref_idx: f32,
}

Material :: union {
    Lambertian,
    Metal,
    Dielectric,
}

material_scatter :: proc(material: Material, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    switch m in material {
        case Lambertian: {
            return lambertian_scatter(m, r, hit, attenuation, scattered)
        }
        case Metal: {
            return metal_scatter(m, r, hit, attenuation, scattered)
        }
        case Dielectric: {
            return dielectric_scatter(m, r, hit, attenuation, scattered)
        }
    }

    return false;
}

lambertian_scatter :: proc(m: Lambertian, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    target := hit.p + hit.normal + random_in_unit_sphere()
    scattered.a = hit.p
    scattered.b = target-hit.p
    attenuation^ = m.albedo

    return true;
}


metal_scatter :: proc(m: Metal, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    reflected := reflect(vec3_unit_vec(ray_direction(r)), hit.normal)
    scattered.a = hit.p
    scattered.b = reflected + m.roughness*random_in_unit_sphere()
    attenuation^ = m.albedo

    return (vec3_dot(ray_direction(scattered^), hit.normal) > 0)
}

dielectric_scatter :: proc(m: Dielectric, r: Ray, hit: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    outward_normal: Vec3
    refracted: Vec3
    ni_over_nt: f32
    reflect_prob: f32
    cosine: f32
    reflected := reflect(ray_direction(r), hit.normal)
    attenuation^ = Vec3{1, 1, 1}

    if vec3_dot(ray_direction(r), hit.normal) > 0 {
        outward_normal = -hit.normal
        ni_over_nt = m.ref_idx
        cosine = m.ref_idx*vec3_dot(ray_direction(r), hit.normal) / vec3_len(ray_direction(r))
    } else {
        outward_normal = hit.normal
        ni_over_nt = 1 / m.ref_idx
        cosine = -vec3_dot(ray_direction(r), hit.normal) / vec3_len(ray_direction(r))
    }

    if refract(ray_direction(r), outward_normal, ni_over_nt, &refracted) {
        reflect_prob = schlick(cosine, m.ref_idx)
    } else {
        scattered.a = hit.p
        scattered.b = reflected
    }

    if rand.float32() < reflect_prob {
        scattered.a = hit.p
        scattered.b = reflected
    } else {
        scattered.a = hit.p
        scattered.b = refracted
    }

    return true
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

@(private="file")
refract :: proc(v, n: Vec3, ni_over_nt: f32, refracted: ^Vec3) -> bool {
    uv := vec3_unit_vec(v)
    dt := vec3_dot(uv, n)
    discriminant := 1 - ni_over_nt*ni_over_nt*(1-dt*dt)

    if discriminant > 0 {
        refracted^ = ni_over_nt*(uv - n*dt) - n*math.sqrt_f32(discriminant)
        return true
    }

    return false
}

@(private="file")
schlick :: proc(cosine, ref_idx: f32) -> f32 {
    r0 := (1 - ref_idx) / (1 + ref_idx)
    r0 = r0*r0

    return r0 + (1 - r0)*math.pow_f32((1 - cosine), 5)
}