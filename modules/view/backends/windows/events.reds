Red/System [
	Title:	"Windows events handling"
	Author: "Nenad Rakocevic"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#enum event-action! [
	EVT_NO_PROCESS							;-- no further msg processing allowed
	EVT_DISPATCH							;-- allow DispatchMessage call only
	EVT_DISPATCH_AND_PROCESS				;-- allow full post-processing of the msg
]

gui-evt: declare red-event!					;-- low-level event value slot
gui-evt/header: TYPE_EVENT

oldBaseWndProc:	0

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		handle [handle!]
		face   [red-object!]
		msg    [tagMSG]
][
	msg: as tagMSG evt/msg
	handle: get-widget-handle msg
	if handle = as handle! -1 [				;-- filter out unwanted events
		return as red-value! none-value
	]

	face: as red-object! stack/push*
	face/header:		  GetWindowLong handle wc-offset
	face/ctx:	 as node! GetWindowLong handle wc-offset + 4
	face/class:			  GetWindowLong handle wc-offset + 8
	face/on-set: as node! GetWindowLong handle wc-offset + 12
	as red-value! face
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		offset [red-pair!]
		int  [red-integer!]
		value  [integer!]
		msg    [tagMSG]
][
	either evt/type <= EVT_MOVE [
		msg: as tagMSG evt/msg

		offset: as red-pair! stack/push*
		offset/header: TYPE_PAIR
		either evt/type = EVT_WHEEL [
			offset/x: 0
			offset/y: (msg/wParam >> 16) / WHEEL_DELTA
		][
			value: msg/lParam

			offset/x: WIN32_LOWORD(value)
			offset/y: WIN32_HIWORD(value)
		]
		
		as red-value! offset
	][
		as red-value! none-value
	]
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		char [red-char!]
][
	as red-value! switch evt/type [
		EVT_KEY [
			either evt/flags and EVT_FLAG_KEY_DOWN <> 0 [
				switch evt/flags and FFFFh [
					VK_PRIOR	[_page-up]
					VK_NEXT		[_page_down]
					VK_END		[_end]
					VK_HOME		[_home]
					VK_LEFT		[_left]
					VK_UP		[_up]
					VK_RIGHT	[_right]
					VK_DOWN		[_down]
					VK_INSERT	[_insert]
					VK_DELETE	[_delete]
					VK_F1		[_F1]
					VK_F2		[_F2]
					VK_F3		[_F3]
					VK_F4		[_F4]
					VK_F5		[_F5]
					VK_F6		[_F6]
					VK_F7		[_F7]
					VK_F8		[_F8]
					VK_F9		[_F9]
					VK_F10		[_F10]
					VK_F11		[_F11]
					VK_F12		[_F12]
					default		[none-value]
				]
			][
				char: as red-char! stack/push*
				char/header: TYPE_CHAR
				char/value: evt/flags and FFFFh
				as red-value! char
			]
		]
		default [as red-value! none-value]
	]
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
][
	as red-value! either evt/type = EVT_MENU [
		word/push* evt/flags and FFFFh
	][
		integer/push evt/flags and FFFFh
	]
]

make-event: func [
	msg		[tagMSG]
	flags	[integer!]
	type	[integer!]
	return: [integer!]
	/local
		res	  [red-word!]
		word  [red-word!]
		sym	  [integer!]
		state [integer!]
		key	  [integer!]
][
	gui-evt/type:  type
	gui-evt/msg:   as byte-ptr! msg
	gui-evt/flags: 0

	state: EVT_DISPATCH_AND_PROCESS

	switch type [
		EVT_KEY_DOWN [
			key: msg/wParam and FFFFh
			if key = VK_PROCESSKEY [return EVT_DISPATCH]  ;-- IME-friendly exit
			gui-evt/flags: key or EVT_FLAG_KEY_DOWN
			gui-evt/type: EVT_KEY
			state: EVT_DISPATCH
		]
		EVT_KEY [
			gui-evt/flags: msg/wParam and FFFFh
		]
		EVT_SELECT [
			word: as red-word! get-facet msg FACE_OBJ_TYPE
			assert TYPE_OF(word) = TYPE_WORD
			if word/symbol = drop-down [get-text msg flags]
			gui-evt/flags: flags + 1 and FFFFh	;-- index is one-based for string!
		]
		EVT_CHANGE [
			unless zero? flags [get-text msg -1] ;-- get text if not done already
		]
		EVT_MENU [gui-evt/flags: flags and FFFFh]	;-- symbol ID of the menu
		default	 [0]
	]

	#call [system/view/awake gui-evt]

	res: as red-word! stack/arguments
	if TYPE_OF(res) = TYPE_WORD [
		sym: symbol/resolve res/symbol
		case [
			sym = done [state: EVT_DISPATCH]	;-- prevent other high-level events
			sym = stop [state: EVT_NO_PROCESS]	;-- prevent all other events
			true 	   [0]						;-- ignore others
		]
	]
	state
]

call-custom-proc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	/local
		p	 [ext-class!]
		proc [wndproc-cb!]
][
	p: ext-classes
	while [p < ext-cls-tail][
		proc: as wndproc-cb! p/parent-proc
		unless null? :proc [proc hWnd msg wParam lParam]
		p: p + 1
	]
]

paint-background: func [
	hWnd	[handle!]
	hDC		[handle!]
	return: [logic!]
	/local
		rect   [RECT_STRUCT]
		hBrush [handle!]
		color  [integer!]
][
	color: to-bgr as node! GetWindowLong hWnd wc-offset + 4
	if color = -1 [return false]

	hBrush: CreateSolidBrush color
	rect: declare RECT_STRUCT
	GetClientRect hWnd rect
	FillRect hDC rect hBrush
	DeleteObject hBrush
	true
]

init-current-msg: func [
	/local
		pos [integer!]
][
	current-msg: declare TAGmsg
	pos: GetMessagePos
	current-msg/x: WIN32_LOWORD(pos)
	current-msg/y: WIN32_HIWORD(pos)
]

WndProc: func [
	hWnd	[handle!]
	msg		[integer!]
	wParam	[integer!]
	lParam	[integer!]
	return: [integer!]
	/local
		type   [red-word!]
		idx	   [integer!]
		res	   [integer!]
		color  [integer!]
		handle [handle!]
		nmhdr  [tagNMHDR]
][
	switch msg [
		WM_COMMAND [
			if all [zero? lParam wParam < 1000][ ;-- heuristic to detect a menu selection (--)'
				unless null? menu-handle [
					res: get-menu-id menu-handle menu-selected
					if null? menu-origin [menu-origin: hWnd]
					current-msg/hWnd: menu-origin
					make-event current-msg res EVT_MENU
					unless null? menu-ctx [DestroyMenu menu-ctx]
					menu-origin: null
					return DefWindowProc hWnd msg wParam lParam
				]
			]
			switch WIN32_HIWORD(wParam) [
				BN_CLICKED [
					type: as red-word! get-facet current-msg FACE_OBJ_TYPE
					make-event current-msg 0 EVT_CLICK	;-- should be *after* get-facet call (Windows closing on click case)
					if any [
						type/symbol = check
						type/symbol = radio
					][
						current-msg/hWnd: as handle! lParam	;-- force child handle
						if get-logic-state current-msg [
							make-event current-msg 0 EVT_CHANGE
						]
					]
				]
				EN_CHANGE [					;-- sent also by CreateWindow
					unless null? current-msg [
						current-msg/hWnd: as handle! lParam	;-- force Edit handle
						make-event current-msg -1 EVT_CHANGE
					]
					0
				]
				CBN_SELCHANGE [
					current-msg/hWnd: as handle! lParam	;-- force ListBox or Combobox handle
					type: as red-word! get-facet current-msg FACE_OBJ_TYPE
					res: either type/symbol = text-list [LB_GETCURSEL][CB_GETCURSEL]
					idx: as-integer SendMessage as handle! lParam res 0 0
					res: make-event current-msg idx EVT_SELECT
					get-selected current-msg idx + 1
					if res = EVT_DISPATCH_AND_PROCESS [
						make-event current-msg 0 EVT_CHANGE
					]
				]
				CBN_EDITCHANGE [
					current-msg/hWnd: as handle! lParam	;-- force Combobox handle
					type: as red-word! get-facet current-msg FACE_OBJ_TYPE
					unless type/symbol = text-list [
						make-event current-msg -1 EVT_CHANGE
					]
				]
				default [0]
			]
		]
		WM_NOTIFY [
			nmhdr: as tagNMHDR lParam
			switch nmhdr/code [
				TCN_SELCHANGING [return process-tab-select nmhdr/hWndFrom]
				TCN_SELCHANGE	[process-tab-change nmhdr/hWndFrom]
				default [0]
			]
		]
		WM_VSCROLL
		WM_HSCROLL [
			unless zero? lParam [			;-- message from trackbar
				current-msg/hWnd: as handle! lParam	;-- trackbar handle
				get-slider-pos current-msg
				make-event current-msg 0 EVT_CHANGE
				return 0
			]
		]
		WM_MOUSEWHEEL [
			current-msg/hWnd: as handle! lParam
			make-event current-msg 0 EVT_WHEEL
			return 0
		]
		WM_ERASEBKGND [
			if paint-background hWnd as handle! wParam [return 1]
		]
		WM_CTLCOLORBTN
		WM_CTLCOLOREDIT
		WM_CTLCOLORSTATIC 
		WM_CTLCOLORLISTBOX 
		WM_CTLCOLORSCROLLBAR [
			if null? current-msg [init-current-msg]
			current-msg/hWnd: as handle! lParam	;-- force child handle
			handle: get-widget-handle current-msg
			if handle <> as handle! -1 [
				color: to-bgr as node! GetWindowLong handle wc-offset + 4
				if color <> -1 [
					SetBkMode as handle! wParam BK_TRANSPARENT 
					SetDCBrushColor as handle! wParam color
					return as-integer GetStockObject DC_BRUSH
				]
			]
		]
		WM_ENTERMENULOOP [
			if zero? wParam [							;-- reset if entering menu bar
				menu-origin: null
				menu-ctx: null
			]
		]
		WM_MENUSELECT [
			if wParam <> FFFF0000h [
				menu-selected: WIN32_LOWORD(wParam)
				menu-handle: as handle! lParam
			]
			return 0
		]
		WM_CLOSE [
			res: make-event current-msg 0 EVT_CLOSE
			if res  = EVT_DISPATCH_AND_PROCESS [return 0]	;-- continue
			if res <= EVT_DISPATCH   [free-handles hWnd]	;-- done
			if res  = EVT_NO_PROCESS [PostQuitMessage 0]	;-- stop
			return 0
		]
		default [0]
	]
	if ext-parent-proc? [call-custom-proc hWnd msg wParam lParam]

	DefWindowProc hWnd msg wParam lParam
]

pre-process: func [
	msg		[tagMSG]
	return: [integer!]
	/local
		lParam [integer!]
		pt	   [tagPOINT]
][
	switch msg/msg [
		WM_LBUTTONDOWN	[
			menu-origin: null				;-- reset if user clicks on menu bar
			menu-ctx: null
			make-event msg 0 EVT_LEFT_DOWN
		]
		WM_LBUTTONUP	[make-event msg 0 EVT_LEFT_UP]
		WM_RBUTTONDOWN	[
			lParam: msg/lParam
			pt: declare tagPOINT
			pt/x: WIN32_LOWORD(lParam)
			pt/y: WIN32_HIWORD(lParam)
			ClientToScreen msg/hWnd pt
			menu-origin: null
			menu-ctx: null
			either show-context-menu msg pt/x pt/y [
				EVT_NO_PROCESS
			][
				make-event msg 0 EVT_RIGHT_DOWN
			]
		]
		WM_RBUTTONUP	[make-event msg 0 EVT_RIGHT_UP]
		WM_MBUTTONDOWN	[make-event msg 0 EVT_MIDDLE_DOWN]
		WM_MBUTTONUP	[make-event msg 0 EVT_MIDDLE_UP]
		WM_HSCROLL [
			get-slider-pos msg
			make-event current-msg 0 EVT_CHANGE
		]
		WM_KEYDOWN		[make-event msg 0 EVT_KEY_DOWN]
		WM_SYSKEYUP
		WM_KEYUP		[make-event msg 0 EVT_KEY_UP]
		WM_SYSKEYDOWN	[
			make-event msg 0 EVT_KEY_DOWN
			EVT_NO_PROCESS
		]
		WM_LBUTTONDBLCLK [
			make-event msg 0 EVT_DBL_CLICK
			EVT_DISPATCH_AND_PROCESS
		]
		;WM_DESTROY []
		default			[EVT_DISPATCH_AND_PROCESS]
	]
]

post-process: func [
	msg	[tagMSG]
	/local
		wParam [integer!]
][
	switch msg/msg [
		WM_CHAR [make-event msg 0 EVT_KEY]
		default [0]
	]
]

do-events: func [
	no-wait? [logic!]
	/local
		msg	  [tagMSG]
		state [integer!]
][
	msg: declare tagMSG

	while [0 < GetMessage msg null 0 0][
		TranslateMessage msg
		state: pre-process msg
		if state >= EVT_DISPATCH [
			current-msg: msg
			DispatchMessage msg
			if state = EVT_DISPATCH_AND_PROCESS [
				post-process msg
			]
		]
		if no-wait? [exit]
	]
]