if(!SAVE_ROOMS){
	if(room_exists(room_next(room)) && keyboard_check_released(vk_right)) room_goto_next();
	if(room_exists(room_previous(room)) && keyboard_check_released(vk_left)) room_goto_previous();
}