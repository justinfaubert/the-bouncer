// A person: a surface (look/surface.gdshader) cut like a woodblock. The light falls in planes
// with gouged edges, the hollows of a face take the ink and its ridges stand up white.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

#define CARVED
#include "res://look/surface.gdshaderinc"
