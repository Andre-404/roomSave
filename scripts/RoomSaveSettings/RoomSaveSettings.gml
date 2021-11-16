//what layer types to save 
#macro SAVE_FLAGS RoomSaveFlag.object | RoomSaveFlag.tile | RoomSaveFlag.sprite | RoomSaveFlag.background
#macro LOAD_FLAGS RoomSaveFlag.object | RoomSaveFlag.tile | RoomSaveFlag.sprite | RoomSaveFlag.background

//wether to save persistent object(default is false since you have to enter a room to save
//which is likely done with a help of a persistent object
#macro SAVE_PERSISTENT_OBJECTS false


//System stuff
enum RoomSaveFlag {
	object = 1,
	tile = 2,
	sprite = 4,
	background = 8
}

function GetObjectName(objInd){
	var str = object_get_name(objInd);
	return str;
}