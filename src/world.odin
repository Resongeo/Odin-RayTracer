package main

World :: struct {
    spheres: [dynamic]Sphere,
}

world_hit :: proc(world: World, r: Ray, t_min, t_max: f32, hit: ^Hit_Record) -> bool {
    temp_hit: Hit_Record
    hit_anything := false
    closest_so_far := t_max

    for s in world.spheres {
        if sphere_hit(s, r, t_min, closest_so_far, &temp_hit) {
            hit_anything = true
            closest_so_far = temp_hit.t
            hit.t = temp_hit.t
            hit.p = temp_hit.p
            hit.normal = temp_hit.normal
        }
    }

    return hit_anything
}