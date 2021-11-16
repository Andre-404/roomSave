//save rooms
function RoomSave(roomIndex, mainStruct){
	var lArr = [];
	var layers = layer_get_all();
	var size_l = array_length(layers);
	//loops over every layer in the room
	for(var i = 0; i < size_l; i++){
		var lID = layers[i];
		var lS = {};
		var name = layer_get_name(lID);
		var lElementArr = layer_get_all_elements(lID);
		//if this layer has no elements we don't save it, this can be changed with the SAVE_EMPTY_LAYERS macro
		var lType = array_length(lElementArr) > 0 || SAVE_EMPTY_LAYERS ? layer_get_element_type(lElementArr[0]) : -1;
		if(lType == -1) continue;
		//we check the flags to see if the user has manually decided to not save a particular asset type
		switch(lType){
			case layerelementtype_background:
				if(SAVE_FLAGS & RoomSaveFlag.background) RoomSaveBackground(lID,lElementArr, lS); break;
			case layerelementtype_instance: 
				if(SAVE_FLAGS & RoomSaveFlag.object) RoomSaveObjects(lID, lElementArr, lS); break;
			
			case layerelementtype_sprite: 
				if(SAVE_FLAGS & RoomSaveFlag.sprite) RoomSaveSprites(lID, lElementArr, lS); break;
			
			case layerelementtype_tilemap: 
				if(SAVE_FLAGS & RoomSaveFlag.tile) RoomSaveTilemap(lID, lElementArr, lS); break;
			
		}
		if(!variable_struct_exists(lS, "type")) continue; //if this layer is of a asset type that's not supported, we don't save it
		lS.name = name;
		lS.depth = layer_get_depth(lID);
		array_push(lArr, lS);
	}
	var rW = room_width;
	var rH = room_height;
	var rN = room_get_name(roomIndex);
	mainStruct.layers = lArr;
	mainStruct.name = rN;
	mainStruct.roomSettings = {width : rW, height : rH};
	return mainStruct;
}

function RoomSaveObjects(lID, lElArr, struct){
	var arr = [];
	//loops over every object, saving it
	for(var i = 0; i < array_length(lElArr); i++){
		var s = new SaveObject(arr, layer_instance_get_instance(lElArr[i]));
	}
	struct.instances = arr;
	struct.type = "InstanceLayer";
}

function SaveObject(arr, oID) constructor {
	//here you can play around with which variables you want to save, 
	//since the saver object has to visit the room in order to save it, all object will run their create event
	x = oID.x;
	y = oID.y;
	scaleX = oID.image_xscale;
	scaleY = oID.image_yscale;
	name = GetObjectName(oID.object_index);
	//you might not want to save persistent objects(like the saver)
	if(SAVE_PERSISTENT_OBJECTS){
		array_push(arr, self);
	}else{
		if(!object_get_persistent(oID.object_index)) array_push(arr, self);
	}
}

function RoomSaveTilemap(lID, lElArr, struct){
	//loops over every tile in the layer and saves it's value, this value can be used for
	//any layer that has the same tileset(even in other projects!)
	struct.type = "TileLayer";
	var tm = layer_tilemap_get_id(lID);
	var tsn = tileset_get_name(tilemap_get_tileset(tm));
	var tmw = tilemap_get_width(tm);
	var tmh = tilemap_get_height(tm);
	var tw = tilemap_get_tile_width(tm);
	var th = tilemap_get_tile_height(tm);
	var tileArr = [];
	for(var i = 0; i < tmh; i++){
		for(var j = 0; j < tmw; j++){
			var tile = tilemap_get(tm, j, i);
			array_push(tileArr, tile);
		}
	}
	var tms = {tileData : tileArr, widthCells : tmw, heightCells : tmh};
	struct.tiles = tms;
	struct.cellWidth = tw;
	struct.cellHeight = th;
	struct.tileset = tsn;
}
	
function RoomSaveSprites(lID, lElArr, struct){
	var arr = [];
	for(var i = 0; i < array_length(lElArr); i++){
		array_push(arr, new SaveSprite(lElArr[i]));
	}
	struct.sprites = arr;
	struct.type = "SpriteLayer";
}

function SaveSprite(sID) constructor {
	//saves the most basic information about the sprite, can be modified to save anything
	name = sprite_get_name(sID);
	x = layer_sprite_get_x(sID);
	y = layer_sprite_get_y(sID);
	scaleX = layer_sprite_get_xscale(sID);
	scaleY = layer_sprite_get_yscale(sID);
}

function RoomSaveBackground(lID, lElArr, struct){
	//saves the background and it's properties, can be modified to suit your needs
	var bgID = layer_background_get_id(lID);
	var bgB = layer_background_get_blend(bgID);
	var bgS = layer_background_get_sprite(bgID) != -1 ? sprite_get_name(layer_background_get_sprite(bgID)) : -1;
	var bgA = layer_background_get_alpha(bgID);
	var bgHT = layer_background_get_htiled(bgID);
	var bgVT = layer_background_get_vtiled(bgID);
	var bgSp = layer_background_get_speed(bgID);
	var bgSt = layer_background_get_stretch(bgID);
	
	struct.backgroundSprite = bgS;
	struct.backgroundBlend = bgB;
	struct.backgroundAlpha = bgA;
	struct.backgroundHTile = bgHT;
	struct.backgroundVTile = bgVT;
	struct.backgroundSpeed = bgSp;
	struct.backgroundStretch = bgSt;
	struct.type = "BackgroundLayer";
}
	
//Loading
function RoomLoad(struct, _x, _y){
	RoomLoadLayers(struct.layers, _x, _y);
}

function RoomLoadLayers(lArr, _x, _y){
	var l = array_length(lArr);
	//loops over every layer inside the room struct
	for(var i = 0; i < l; i++){
		RoomLoadAddLayer(lArr[i], _x, _y);
	}
}

function RoomLoadAddLayer(lStruct, _x, _y){
	var lType = lStruct.type;
	var lName = lStruct.name;
	var lDepth = lStruct.depth;
	//if the layer we're trying to create already exists
	var lCheckID = layer_get_id(lName);
	if(lCheckID == -1) var lID = layer_create(lDepth, lName);
	else var lID = lCheckID;
	
	//uses the flags to see if the user has disabled any of the assets from being loaded
	switch(lType){
		case "InstanceLayer":
			if(LOAD_FLAGS & RoomSaveFlag.object) 
				RoomLoadObjects(lStruct.instances, lID, _x, _y); break;
		case "TileLayer": 
			if(LOAD_FLAGS & RoomSaveFlag.tile) 
				RoomLoadTilemap(lStruct.tiles, lStruct.tileset, lID, lStruct.cellWidth, lStruct.cellHeight, _x, _y); break;
		case "SpriteLayer": 
			if(LOAD_FLAGS & RoomSaveFlag.sprite) 
				RoomLoadSprites(lStruct.sprites, lID, _x, _y); break;
		case "BackgroundLayer": 
			if(LOAD_FLAGS & RoomSaveFlag.background) 
				RoomLoadBackground(lStruct, lID, _x, _y); break;
	}
	
}

function RoomLoadObjects(elArr, lID, _x, _y){
	//loops over every instance in the layer
	var l = array_length(elArr);
	for(var i = 0; i < l; i++){
		var oS = elArr[i];
		var oName = oS.name;
		//the name of the dummy object that was saved MUST match the name of the actual object you wish to create
		//otherwise this doesn't work
		var oID = asset_get_index(oName);
		if(oID == -1) show_message("Object: " + oName + " doesn't exists");
		var obj = instance_create_layer(0, 0, lID, oID);
		//here we load all the variables we saved 
		//you need to do this for every variable you save
		var oSx = oS.scaleX;
		var oSy = oS.scaleY;
		var oX = oS.x;
		var oY = oS.y;
		
		obj.x = oX + _x;
		obj.y = oY + _y;
		obj.image_xscale = oSx;
		obj.image_yscale = oSy;
	}
}
	
function RoomLoadTilemap(tstS, tN, lID, cw, ch, _x, _y){
	//adds a tilemap to the layer(if check in case the user created the layer manually)
	var tAssetIndex = asset_get_index(tN);
	if(layer_tilemap_get_id(lID) == -1) {
		var tID = layer_tilemap_create(lID, 0, 0, tAssetIndex, room_width div cw, room_height div ch);
	}else{
		var tID = layer_tilemap_get_id(lID);
	}
	//loops over every position in the array and sets the cell to the correct value
	var tw = tstS.widthCells;
	var th = tstS.heightCells;
	var tArr = tstS.tileData;
	var tArrL = array_length(tArr);
	for(var i = 0; i < tArrL; i++){
		var cx = (i mod tw) + _x div cw;
		var cy = (i div tw) + _y div ch;
		if(tArr[i] > 0) tilemap_set(tID, tArr[i], cx, cy);
	}
}
	
function RoomLoadSprites(elArr, lID, _x, _y){
	for(var i = 0; i < elArr; i++){
		//here you would add any variable you decied to save with the sprite
		var sS = elArr[i];
		var sx = sS.x + _x;
		var sy = sS.y + _y;
		var sSx = sS.scaleX;
		var sSy = sS.scaleY;
		var sID = asset_get_index(sS.name);
		
		var newS = layer_sprite_create(lID, sx, sy, sID);
		layer_sprite_xscale(newS, sSx);
		layer_sprite_yscale(newS, sSy);
	}
}
	
function RoomLoadBackground(bgS, lID, _x, _y){
	//load the background 
	var bgID = layer_background_create(lID, (bgS.backgroundSprite != -1 ? asset_get_index(bgS.backgroundSprite) : -1));
	layer_background_alpha(bgID, bgS.backgroundAlpha);
	layer_background_blend(bgID, bgS.backgroundBlend);
	layer_background_speed(bgID, bgS.backgroundSpeed);
	layer_background_htiled(bgID, bgS.backgroundHTile);
	layer_background_vtiled(bgID, bgS.backgroundVTile);
	layer_background_stretch(bgID, bgS.backgroundStretch);
}