if(SAVE_ROOMS){
	SaveRoom(room, roomData);
	if(room_exists(room_next(room)) && !done) room_goto_next();
	else if(!done){
		done = true;
		var str = snap_to_json(roomData, FORMAT_JSON_PRETTY, false);
		var b = buffer_create(1, buffer_grow,1);
		buffer_write(b, buffer_string, str);
		buffer_save(b, SAVE_FOLDER_PATH + ROOM_FILE_NAME);
		buffer_delete(b);
		writeFileToDisc();
		game_end();
	}
}