global.outputFile = "";

function FilterRoom(_room, _mainArr){
	var name = room_get_name(_room);
	writeToFile("Errors while saving room '" + name + "':");
	try{
	var _roomStruct = RoomSave(room, {})
	array_push(_mainArr, _roomStruct);
	writeToFile("None");
	} catch(e){
		writeToFile("Error has occurd while saving room '" + name + "'" + "\n" + e.longMessage);
	}
}

function writeToFile(str){
	global.outputFile += str + "\n";
}

function writeFileToDisc(){
	if(!WRITE_LOG) exit;
	var b = buffer_create(1, buffer_grow,1);
	buffer_write(b, buffer_string, global.outputFile);
	buffer_save(b, SAVE_FOLDER_PATH + "\\roomSave_log.txt");
	buffer_delete(b);
}

