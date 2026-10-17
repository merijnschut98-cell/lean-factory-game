extends TestCase
## The runner itself (tests/run_tests.gd). The game frees UI with queue_free
## (UiPanel.clear, the creator booth's models); a SceneTree script that never
## lets a frame pass never deletes them, and one suite run grew past 5 GB that
## way. The runner lets a frame pass after every test, so what a test
## queue_free'd is gone before the next one starts. The two tests below run in
## this order (declaration order) and share the static weakref.

static var _queued: WeakRef


func test_a_node_is_queued_for_deletion() -> void:
	var node := Node.new()
	node.queue_free()
	_queued = weakref(node)
	assert_true(is_instance_valid(node), "queue_free waits for the end of the frame")


func test_b_what_the_previous_test_queued_is_freed() -> void:
	assert_true(_queued != null, "test_a ran first")
	assert_true(_queued != null and _queued.get_ref() == null, "the queued node is still alive")
