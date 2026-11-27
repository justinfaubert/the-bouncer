# The poster girls

The women on the beer posters in the Sov (`godot/textures/dress_boors.png`, `dress_mildcat.png`,
`dress_unlucky.png`) are rendered, not drawn: Quaternius's CC0 *Universal Base Characters* woman,
posed, dressed in the brand's colours and lit like a 1990s studio shoot, then printed and aged round
her by `godot/tools/dressing.py`.

The kit isn't in the repo. Hutch's copy is in the project files
(`Universal Base Characters[Standard].zip`); unzip it somewhere and point `UBC_KIT` at the folder.

```sh
export UBC_KIT="/path/to/Universal Base Characters[Standard]"
export GIRLS_WORK=/tmp/last-call-girls
python3 godot/tools/dressing.py girls          # her skin with the bikini recoloured, and the can's label
xvfb-run -a -s "-screen 0 1280x1024x24" env VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json \
  godot --path tools/poster_girls -s render.gd -- "$UBC_KIT" "$GIRLS_WORK" "$PWD/godot"   # the renders
python3 godot/tools/dressing.py boors mildcat unlucky                                     # the posters
```

`render.gd` holds the poses as moves on the skeleton (aim a bone at a direction, turn one, curl a
hand), so a pose is changed by editing a line and rendering again. The props are the game's own
models (the bar stool, the pickup in jade green).
