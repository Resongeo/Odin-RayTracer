package main

import "core:math/rand"

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
			hit^ = temp_hit
		}
	}

	return hit_anything
}

new_random_world :: proc() -> (world: World) {
	append(
		&world.spheres,
		Sphere {
			center = Vec3{0, -1000, 0},
			radius = 1000,
			material = new_material(Lambertian{albedo = Vec3{0.5, 0.5, 0.5}}),
		},
	)

	for a := -11; a < 11; a += 1 {
		for b := -11; b < 11; b += 1 {
			choose_mat := rand.float32()

			center := Vec3{f32(a) + 0.9 * rand.float32(), 0.2, f32(b) + 0.9 * rand.float32()}

			if vec3_len(center - Vec3{4, 0.2, 0}) > 0.9 {

				// Diffuse
				if choose_mat < 0.8 {
					albedo := Vec3 {
						rand.float32() * rand.float32(),
						rand.float32() * rand.float32(),
						rand.float32() * rand.float32(),
					}

					append(
						&world.spheres,
						Sphere {
							center = center,
							radius = 0.2,
							material = new_material(Lambertian{albedo = albedo}),
						},
					)

					// Metal
				} else if choose_mat < 0.95 {
					albedo := Vec3 {
						0.5 * (1 + rand.float32()),
						0.5 * (1 + rand.float32()),
						0.5 * (1 + rand.float32()),
					}

					append(
						&world.spheres,
						Sphere {
							center = center,
							radius = 0.2,
							material = new_material(
								Metal{albedo = albedo, roughness = 0.5 * rand.float32()},
							),
						},
					)

					// Glass
				} else {
					append(
						&world.spheres,
						Sphere {
							center = center,
							radius = 0.2,
							material = new_material(Dielectric{ref_idx = 1.5}),
						},
					)
				}
			}
		}
	}

	append(
		&world.spheres,
		Sphere {
			center = Vec3{0, 1, 0},
			radius = 1.0,
			material = new_material(Dielectric{ref_idx = 1.5}),
		},
	)

	append(
		&world.spheres,
		Sphere {
			center = Vec3{-4, 1, 0},
			radius = 1.0,
			material = new_material(Lambertian{albedo = Vec3{0.4, 0.2, 0.1}}),
		},
	)

	append(
		&world.spheres,
		Sphere {
			center = Vec3{4, 1, 0},
			radius = 1.0,
			material = new_material(Metal{albedo = Vec3{0.7, 0.6, 0.5}, roughness = 0.0}),
		},
	)

	return world
}
