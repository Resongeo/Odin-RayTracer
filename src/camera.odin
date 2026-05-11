package main

Camera :: struct {
    origin:            Vec3,
    vertical:          Vec3,
    horizontal:        Vec3,
    lower_left_corner: Vec3,
}

camera_get_ray :: proc(c: Camera, u, v: f32) -> Ray {
    return {
        c.origin,
        c.lower_left_corner + u*c.horizontal + v*c.vertical - c.origin,
    }
}