package main

Ray :: struct {
    a: Vec3,
    b: Vec3,
}

ray_origin :: proc(r: Ray) -> Vec3 {
    return r.a;
}

ray_direction :: proc(r: Ray) -> Vec3 {
    return r.b;
}

ray_point_at_parameter :: proc(r: Ray, t: f32) -> Vec3 {
    return r.a + t*r.b
}