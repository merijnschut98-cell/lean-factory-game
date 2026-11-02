extends TestCase

var tmp := scratch("test_game_info.json")


func test_loads_built_content() -> void:
	var info := GameInfo.load_from()
	assert_eq(info.error, "")
	assert_eq(info.town, "Nova")
	assert_eq(info.company, "Voltana Netbeheer")


func test_missing_file_reports_error() -> void:
	var info := GameInfo.load_from("res://data/does_not_exist.json")
	assert_true(info.error.begins_with("cannot read"), info.error)


func test_missing_field_reports_error() -> void:
	_write('{"company": "X", "region": "Y"}')
	var info := GameInfo.load_from(tmp)
	assert_true("'town'" in info.error, info.error)


func test_not_an_object_reports_error() -> void:
	_write("[1, 2, 3]")
	assert_true("not a JSON object" in GameInfo.load_from(tmp).error)


func _write(text: String) -> void:
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(text)
	f.close()
