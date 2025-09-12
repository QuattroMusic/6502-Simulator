// Modified version took from the Clipboard module

clipboard_get_text :: (hwnd: HWND) -> string {
	text: string;
	
	if !IsClipboardFormatAvailable(CF_UNICODETEXT) then return text;
	if !OpenClipboard(hwnd) then return text;

	hData := GetClipboardData(CF_UNICODETEXT);
	
	buffer := cast(*u8)GlobalLock(hData);
	
	CP :: CP_UTF8;
	WC :: 0;

	// Phase 1: Figure out how long this is.
	length := WideCharToMultiByte(CP, 0, cast(*u16)hData, -1, null, 0, null, null);

	utf8 := alloc(length);
	WideCharToMultiByte(CP, WC, cast(*u16)hData, -1, utf8, length, null, null);

	if length {
		text.count = length-1;  // Terminating zero.
		text.data  = utf8;
		assert(text.data[length-1] == 0);
	}

	GlobalUnlock(hData);
	CloseClipboard();

	return text;
}

clipboard_set_text :: (hwnd: HWND, text: string) {
	if !OpenClipboard(hwnd) return;

	EmptyClipboard();

	CP :: CP_UTF8;
	WC :: 0;

	length := MultiByteToWideChar(CP, WC, text.data, xx text.count, null, 0);

	auto_release_temp();
	utf16 := cast(*u16, talloc((length + 1) * 2));

	new_length := MultiByteToWideChar(CP, WC, text.data, xx text.count, utf16, length);
	assert(new_length <= length);
	utf16[new_length] = 0;

	clipbuffer := GlobalAlloc(0, xx (new_length*2+2));
	buffer := cast(*u8)GlobalLock(clipbuffer);
	memcpy(buffer, utf16, new_length*2+2);
	GlobalUnlock(clipbuffer);

	SetClipboardData(CF_UNICODETEXT, clipbuffer);
	CloseClipboard();
}

#scope_file
_user32  :: #system_library "User32";

IsClipboardFormatAvailable :: (format: u32) -> s32 #foreign _user32;

#import "Basic";
#import "Windows";
