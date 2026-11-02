class_name PortraitPhoto
## The badge photo (PLAN 2.7b; spec 2026-10-16-creator-and-minimap §1.7): the
## look in the booth, head and shoulders, from the front, rendered once into a
## PlayerProfile.PORTRAIT_SIZE PNG for the save's meta, so the save cards never load 3D. Where
## nothing renders (the headless tests, a CI) it returns no bytes, which every
## user shows as the drawn placeholder; it never blocks the flow.

## Rendered at this multiple and scaled down, for clean edges.
const SUPERSAMPLE := 2


static func can_render() -> bool:
	return DisplayServer.get_name() != "headless"


## The photo of `look` as PNG bytes; empty when nothing renders. Needs
## `parent` in the tree (a few frames pass).
static func take(parent: Node, look: Dictionary) -> PackedByteArray:
	if not can_render() or parent == null or not parent.is_inside_tree():
		return PackedByteArray()
	var size := PlayerProfile.PORTRAIT_SIZE
	var viewport := SubViewport.new()
	viewport.size = size * SUPERSAMPLE
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var booth := CreatorBooth.new()
	viewport.add_child(booth)
	parent.add_child(viewport)
	booth.wear(look)
	booth.frame_photo()
	booth.set_process(false)  # stands still, facing the camera
	for i in 3:
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null or image.is_empty():
		return PackedByteArray()
	image.convert(Image.FORMAT_RGB8)
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return PlayerProfile.valid_portrait(image.save_png_to_buffer())
