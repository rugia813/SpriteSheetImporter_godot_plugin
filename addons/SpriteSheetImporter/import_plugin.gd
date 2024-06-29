@tool
extends EditorImportPlugin

enum Preset { PRESET_DEFAULT }

func _get_importer_name():
	return "snkkid.SpriteSheetImporter"

func _get_visible_name():
	return "Sprite sheet importer"

func _get_recognized_extensions():
	return ["json"]

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "Resource"

func _get_preset_count():
	return Preset.size()

func _get_priority():
	return 1

func _get_preset_name(preset_index):
	return "Default"

func _get_import_options(path, preset_index):
	return [{
			"name": "Import_As_Atlas",
			"default_value": true
			}]

func _get_option_visibility(option, option_name, options):
	return true

func _get_import_order():
	return 200

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	print("Importing sprite sheet from "+source_file, options);

	var sheets = read_sprite_sheet(source_file)
	if typeof(sheets) == TYPE_INT:
		return sheets

	if options.Import_As_Atlas:
		var sheetFolder = source_file.get_basename()+".sprites";
		var err = create_folder(sheetFolder)
		if typeof(err) == TYPE_INT:
			return 1

		var image = ImageTexture.new()
		image = load(source_file.get_base_dir().path_join(sheets.meta.image))

		for sheet in sheets.frames:
			var texture = AtlasTexture.new()
			texture.atlas = image
			var name = sheetFolder+"/"+sheet.filename.get_basename()+".tres"
			texture.region = Rect2(sheet.frame.x,sheet.frame.y,sheet.frame.w,sheet.frame.h)
			save_resource(name, texture)

	return ResourceSaver.save(Resource.new(), "%s.%s" % [save_path, _get_save_extension()])

func save_resource(name, texture):
	create_folder(name.get_base_dir())

	var status = ResourceSaver.save(texture, name)
	if status != OK:
		printerr("Failed to save resource "+name+", ERR: ", status)
		return false
	return true

func read_sprite_sheet(fileName):
	var nbError = 0
	var file = FileAccess.open(fileName, FileAccess.READ)
	if file == null:
		printerr("Failed to load "+fileName)
		printerr(file.get_error())
		return 1
	
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	var dict
	if error == OK:
		dict = json.data
		file.close()

		if !dict:
			nbError = nbError + 1
		if !dict.has("meta"):
			nbError = nbError + 1
		if !dict.meta.has("image"):
			nbError = nbError + 1
		if !dict.has("frames"):
			nbError = nbError + 1
		if dict.frames.size() == 0:
			nbError = nbError + 1
		if !dict.frames[0].has("filename"):
			nbError = nbError + 1
		if !dict.frames[0].has("frame"):
			nbError = nbError + 1
		if !dict.frames[0].frame.has("x"):
			nbError = nbError + 1
		if !dict.frames[0].frame.has("y"):
			nbError = nbError + 1
		if !dict.frames[0].frame.has("w"):
			nbError = nbError + 1
		if !dict.frames[0].frame.has("h"):
			nbError = nbError + 1

	if nbError > 0:
		printerr("Invalid json data in "+fileName)
		return nbError

	return dict

func create_folder(folder):
	if !DirAccess.dir_exists_absolute(folder):
		var dir = DirAccess.make_dir_absolute(folder)
		if dir != OK:
			printerr("Failed to create folder: " + folder, "ERR: ", dir)
			return 1
