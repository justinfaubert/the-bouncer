// A surface in the room. It draws twice. For the eye it's an ordinary lit surface. For the press
// (the mask camera, which sees visual layer 20) it draws how the key block is cut here: a
// threshold for the night ink that makes strokes stuck to the surface, the way a lino cutter
// follows a form, and how strongly its edges take a line.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

#include "res://look/surface.gdshaderinc"
