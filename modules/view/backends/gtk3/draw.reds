Red/System [
	Title:	"Cairo Draw dialect backend"
	Author: "Qingtian Xie, Honix, RCqls"
	File: 	%draw.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %text-box.reds

draw-state!: alias struct! [unused [integer!]]

set-source-color: func [
	cr			[handle!]
	color		[integer!]
	/local
		r		[float!]
		b		[float!]
		g		[float!]
		a		[float!]
][
	r: as-float color and FFh
	r: r / 255.0
	g: as-float color >> 8 and FFh
	g: g / 255.0
	b: as-float color >> 16 and FFh
	b: b / 255.0
	a: as-float color >> 24 and FFh
	a: 1.0 - (a / 255.0)
	cairo_set_source_rgba cr r g b a
]

draw-begin: func [
	ctx			[draw-ctx!]
	cr			[handle!]
	img			[red-image!]
	on-graphic?	[logic!]
	paint?		[logic!]
	return:		[draw-ctx!]
][
	ctx/raw:			cr
	ctx/pen-width:		1.0
	ctx/pen-style:		0
	ctx/pen-color:		0						;-- default: black
	ctx/pen-join:		miter
	ctx/pen-cap:		flat
	ctx/brush-color:	0
	ctx/font-color:		0
	ctx/pen?:			yes
	ctx/brush?:			no
	ctx/pattern:		null

	cairo_set_line_width cr 1.0
	set-source-color cr 0
	ctx
]

draw-end: func [
	dc			[draw-ctx!]
	hWnd		[handle!]
	on-graphic? [logic!]
	cache?		[logic!]
	paint?		[logic!]
][
	0
]

do-paint: func [dc [draw-ctx!] /local cr [handle!]][
	cr: dc/raw
	if dc/brush? [
		cairo_save cr
		either null? dc/pattern [
			set-source-color cr dc/brush-color
		][
			cairo_set_source cr dc/pattern
		]
		cairo_fill_preserve cr
		unless dc/pen? [
			set-source-color cr dc/pen-color 
			cairo_stroke cr
		]
		cairo_restore cr
	]
	if dc/pen? [
		cairo_stroke cr
	]
]

OS-draw-anti-alias: func [
	dc	[draw-ctx!]
	on? [logic!]
][
0
]

OS-draw-line: func [
	dc	   [draw-ctx!]
	point  [red-pair!]
	end	   [red-pair!]
	/local
		cr [handle!]
][
	cr: dc/raw
	while [point <= end][
		cairo_line_to cr as-float point/x as-float point/y
		point: point + 1
	]
	do-paint dc
]

OS-draw-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- 00bbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	dc/pen?: not off?
	if dc/pen-color <> color [
		dc/pen-color: color
		set-source-color dc/raw color
	]
]

OS-draw-fill-pen: func [
	dc	   [draw-ctx!]
	color  [integer!]									;-- 00bbggrr format
	off?   [logic!]
	alpha? [logic!]
][
	dc/brush?: not off?
	unless null? dc/pattern [
		cairo_pattern_destroy dc/pattern
		dc/pattern: null
	]
	if dc/brush-color <> color [
		dc/brush-color: color
	]
]

OS-draw-line-width: func [
	dc	  [draw-ctx!]
	width [red-value!]
	/local
		w [float!]
][
	w: get-float as red-integer! width
	if dc/pen-width <> w [
		dc/pen-width: w
		cairo_set_line_width dc/raw w
	]
]

OS-draw-box: func [
	dc	  [draw-ctx!]
	upper [red-pair!]
	lower [red-pair!]
	/local
		radius	[red-integer!]
		rad		[integer!]
		x		[float!]
		y		[float!]
		w		[float!]
		h		[float!]
][
	either TYPE_OF(lower) = TYPE_INTEGER [
		radius: as red-integer! lower
		lower:  lower - 1
		rad: radius/value * 2
		;;@@ TBD round box
	][
		x: as-float upper/x
		y: as-float upper/y
		w: as-float lower/x - upper/x
		h: as-float lower/y - upper/y
		cairo_rectangle dc/raw x y w h
		do-paint dc
	]
]

OS-draw-triangle: func [
	dc	  [draw-ctx!]
	start [red-pair!]
][
	loop 3 [
		cairo_line_to dc/raw as-float start/x as-float start/y
		start: start + 1
	]
	cairo_close_path dc/raw								;-- close the triangle
	do-paint dc
]

OS-draw-polygon: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
][
	until [
		cairo_line_to dc/raw as-float start/x as-float start/y
		start: start + 1
		start > end
	]
	cairo_close_path dc/raw
	do-paint dc
]

spline-delta: 1.0 / 25.0

do-spline-step: func [
	ctx		[handle!]
	p0		[red-pair!]
	p1		[red-pair!]
	p2		[red-pair!]
	p3		[red-pair!]
	/local
		t		[float!]
		t2		[float!]
		t3		[float!]
		x		[float!]
		y		[float!]
][
		t: 0.0
		loop 25 [
			t: t + spline-delta
			t2: t * t
			t3: t2 * t
			
			x:
			   2.0 * (as-float p1/x) + ((as-float p2/x) - (as-float p0/x) * t) +
			   ((2.0 * (as-float p0/x) - (5.0 * (as-float p1/x)) + (4.0 * (as-float p2/x)) - (as-float p3/x)) * t2) +
			   (3.0 * ((as-float p1/x) - (as-float p2/x)) + (as-float p3/x) - (as-float p0/x) * t3) * 0.5
			y:
			   2.0 * (as-float p1/y) + ((as-float p2/y) - (as-float p0/y) * t) +
			   ((2.0 * (as-float p0/y) - (5.0 * (as-float p1/y)) + (4.0 * (as-float p2/y)) - (as-float p3/y)) * t2) +
			   (3.0 * ((as-float p1/y) - (as-float p2/y)) + (as-float p3/y) - (as-float p0/y) * t3) * 0.5

			cairo_line_to ctx x y
		]
]

OS-draw-spline: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	closed? [logic!]
	/local
		ctx		[handle!]
		point	[red-pair!]
		stop	[red-pair!]
][
	if (as-integer end - start) >> 4 = 1 [		;-- two points input
		OS-draw-line dc start end				;-- draw a line
		exit
	]

	ctx: dc/raw

	either closed? [
		do-spline-step ctx
			end
			start
			start + 1
			start + 2
	][
		do-spline-step ctx 
			start
			start
			start + 1
			start + 2
	]
	
	point: start
	stop: end - 3

	while [point <= stop] [
		do-spline-step ctx
			point
			point + 1
			point + 2
			point + 3
		point: point + 1
	]

	either closed? [
		do-spline-step ctx
			end - 2
			end - 1
			end
			start
		do-spline-step ctx
			end - 1
			end
			start
			start + 1
		cairo_close_path ctx 
	][
		do-spline-step ctx
			end - 2
			end - 1
			end
			end
	]

	do-paint dc
]

OS-draw-circle: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	radius [red-integer!]
	/local
		ctx   [handle!]
		rad-x [integer!]
		rad-y [integer!]
		w	  [float!]
		h	  [float!]
		f	  [red-float!]
][
	ctx: dc/raw

	either TYPE_OF(radius) = TYPE_INTEGER [
		either center + 1 = radius [					;-- center, radius
			rad-x: radius/value
			rad-y: rad-x
		][
			rad-y: radius/value							;-- center, radius-x, radius-y
			radius: radius - 1
			rad-x: radius/value
		]
		w: as float! rad-x * 2
		h: as float! rad-y * 2
	][
		f: as red-float! radius
		either center + 1 = radius [
			rad-x: as-integer f/value + 0.75
			rad-y: rad-x
			w: as float! f/value * 2.0
			h: w
		][
			rad-y: as-integer f/value + 0.75
			h: as float! f/value * 2.0
			f: f - 1
			rad-x: as-integer f/value + 0.75
			w: as float! f/value * 2.0
		]
	]

	cairo_save ctx
	cairo_translate ctx as-float center/x
						as-float center/y
	cairo_scale ctx as-float rad-x
					as-float rad-y
	cairo_arc ctx 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore ctx
	do-paint dc
]

OS-draw-ellipse: func [
	dc		 [draw-ctx!]
	upper	 [red-pair!]
	diameter [red-pair!]
	/local
		ctx   [handle!]
		rad-x [integer!]
		rad-y [integer!]
][
	ctx: dc/raw
	rad-x: diameter/x / 2
	rad-y: diameter/y / 2

	cairo_save ctx
	cairo_translate ctx as-float upper/x + rad-x
						as-float upper/y + rad-y
	cairo_scale ctx as-float rad-x
					as-float rad-y
	cairo_arc ctx 0.0 0.0 1.0 0.0 2.0 * pi
	cairo_restore ctx
	do-paint dc
]

; move this to draw-ctx?
font-size: 10.0						;-- used to find top line

OS-draw-font: func [
	dc		[draw-ctx!]
	font	[red-object!]
	/local
		cr       [handle!]
		values   [red-value!]
		style    [red-word!]
		blk      [red-block!]
		len      [integer!]
		sym      [integer!]
		str      [red-string!]
		name     [c-string!]
		size     [red-integer!]
		css      [c-string!]
		color    [red-tuple!]
		bgcolor  [red-tuple!]
		rgba     [c-string!]
		slant    [integer!]
		weight   [integer!]
		extents  [cairo_font_extents_t!]
][
	cr: dc/raw

	values: object/get-values font

	;name:
	str: 	as red-string!	values + FONT_OBJ_NAME
	size:	as red-integer!	values + FONT_OBJ_SIZE
	style:	as red-word!	values + FONT_OBJ_STYLE
	;angle:
	color:	as red-tuple!	values + FONT_OBJ_COLOR
	;anti-alias?:

	dc/font-color: color/array1

	if TYPE_OF(str) = TYPE_STRING [
		len: -1
		name: unicode/to-utf8 str :len
 	]

	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			block/rs-length? blk
		]
		TYPE_WORD	[1]
		default		[0]
	]

	slant: CAIRO_FONT_SLANT_NORMAL
	weight: CAIRO_FONT_WEIGHT_NORMAL
  
	unless zero? len [
		loop len [
			sym: symbol/resolve style/symbol
			case [ 
				sym = _bold      [weight: CAIRO_FONT_WEIGHT_BOLD]
				sym = _italic    [slant: CAIRO_FONT_SLANT_ITALIC]
				sym = _underline []
				sym = _strike    []
				true             []
			]
			style: style + 1
		]
	]

	cairo_select_font_face cr name slant weight

	if TYPE_OF(size) = TYPE_INTEGER [
		extents: declare cairo_font_extents_t!
		cairo_font_extents cr extents

		font-size: as-float size/value
		cairo_set_font_size cr font-size * ((extents/ascent + extents/descent) / extents/ascent)

		;	This technique is little more correct for me. 
		;	This Red example will show the difference:
		;
		;		f: make font! [name: "Arial" size: 120]	
		;		view [base 140x140 draw [font f text 10x10 "A" pen white box 0x10 140x130]]
	]
]

draw-text-at: func [
	dc		[draw-ctx!]
	text	[red-string!]
	color	[integer!]
	x		[integer!]
	y		[integer!]
	/local
		len     [integer!]
		str		[c-string!]
		ctx 	[handle!]
		;attr	[integer!]
		;line	[integer!]
][
	; m: make-CGMatrix 1 0 0 -1 x y
	; str: to-CFString text
	; attr: CFAttributedStringCreate 0 str attrs
	; line: CTLineCreateWithAttributedString attr

	; delta: objc_msgSend_f32 [
	; 	objc_msgSend [attrs sel_getUid "objectForKey:" NSFontAttributeName]
	; 	sel_getUid "ascender"
	; ]
	; m/ty: m/ty + delta
	; CGContextSetTextMatrix ctx m/a m/b m/c m/d m/tx m/ty
	; CTLineDraw line ctx

	; CFRelease str
	; CFRelease attr
	; CFRelease line

	ctx: dc/raw

	len: -1
	str: unicode/to-utf8 text :len
	cairo_move_to ctx as-float x
					  (as-float y) + font-size

	set-source-color ctx color
	cairo_show_text ctx str

	do-paint dc

]


draw-text-box: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	tbox	[red-object!]
	catch?	[logic!]
	/local
		int		[red-integer!]
		values	[red-value!]
		state	[red-block!]
		str		[red-string!]
		bool	[red-logic!]
		layout? [logic!]
		layout	[integer!]
		tc		[integer!]
		idx		[integer!]
		len		[integer!]
		y		[integer!]
		x		[integer!]
		;pt		[CGPoint!]
		clr		[integer!]
][
	values: object/get-values tbox
	str: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(str) <> TYPE_STRING [exit]

	state: as red-block! values + FACE_OBJ_EXT3
	layout?: yes
	if TYPE_OF(state) = TYPE_BLOCK [
		bool: as red-logic! (block/rs-tail state) - 1
		layout?: bool/value
	]
	if layout? [
		clr: either null? dc [0][
			;;TODO: objc_msgSend [dc/font-attrs sel_getUid "objectForKey:" NSForegroundColorAttributeName]
			0
		]
		OS-text-box-layout tbox null clr catch?
	]

	int: as red-integer! block/rs-head state
	layout: int/value
	int: int + 1
	tc: int/value

	; idx: objc_msgSend [layout sel_getUid "glyphRangeForTextContainer:" tc]
	; len: system/cpu/edx
	; x: 0
	; pt: as CGPoint! :x
	; pt/x: as float32! pos/x
	; pt/y: as float32! pos/y
	; objc_msgSend [layout sel_getUid "drawBackgroundForGlyphRange:atPoint:" idx len pt/x pt/y]
	; objc_msgSend [layout sel_getUid "drawGlyphsForGlyphRange:atPoint:" idx len pt/x pt/y]
]


; OLD TO REMOVE: OS-draw-text: func [
; 	dc		[draw-ctx!]
; 	pos		[red-pair!]
; 	text	[red-string!]
; 	catch?	[logic!]
; 	return: [logic!]
; 	/local
; 		ctx		[handle!]
; 		len     [integer!]
; 		str		[c-string!]
; ][
; 	ctx: dc/raw

; 	len: -1
; 	str: unicode/to-utf8 text :len
; 	cairo_move_to ctx as-float pos/x
; 					  (as-float pos/y) + font-size

; 	set-source-color dc/raw dc/font-color
; 	cairo_show_text ctx str

; 	do-paint dc

; 	set-source-color dc/raw dc/pen-color	;-- backup pen color
; 	yes
; ]

OS-draw-text: func [
	dc		[draw-ctx!]
	pos		[red-pair!]
	text	[red-string!]
	catch?	[logic!]
	return: [logic!]
][
	either TYPE_OF(text) = TYPE_STRING [
		draw-text-at dc text dc/font-color pos/x pos/y
	][
		draw-text-box dc pos as red-object! text catch?
	]

	set-source-color dc/raw dc/pen-color	;-- backup pen color
	; brush
	true
]

OS-draw-arc: func [
	dc	   [draw-ctx!]
	center [red-pair!]
	end	   [red-value!]
	/local
		ctx			[handle!]
		radius		[red-pair!]
		angle		[red-integer!]
		begin		[red-integer!]
		cx			[float!]
		cy			[float!]
		rad-x		[float!]
		rad-y		[float!]
		angle-begin [float!]
		angle-end	[float!]
		rad			[float!]
		sweep		[integer!]
		i			[integer!]
		closed?		[logic!]
][
	ctx: dc/raw
	cx: as float! center/x
	cy: as float! center/y
	rad: PI / 180.0

	radius: center + 1
	rad-x: as float! radius/x
	rad-y: as float! radius/y
	begin: as red-integer! radius + 1
	angle-begin: rad * as float! begin/value
	angle: begin + 1
	sweep: angle/value
	i: begin/value + sweep
	angle-end: rad * as float! i

	closed?: angle < end

	cairo_save ctx
	cairo_translate ctx cx    cy
	cairo_scale     ctx rad-x rad-y
	cairo_arc ctx 0.0 0.0 1.0 angle-begin angle-end
	if closed? [
		cairo_close_path ctx
	]
	cairo_restore ctx
	do-paint dc
]

OS-draw-curve: func [
	dc	  [draw-ctx!]
	start [red-pair!]
	end	  [red-pair!]
	/local
		ctx   [handle!]
		p2	  [red-pair!]
		p3	  [red-pair!]
][
	ctx: dc/raw

	if (as-integer end - start) >> 4 = 3    ; four input points 
	[
		cairo_move_to ctx as-float start/x 
						  as-float start/y
		start: start + 1
	]

	p2: start + 1
	p3: start + 2
	cairo_curve_to ctx as-float start/x
					   as-float start/y
					   as-float p2/x
					   as-float p2/y
					   as-float p3/x
					   as-float p3/y
	do-paint dc
]

OS-draw-line-join: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	if dc/pen-join <> style [
		dc/pen-join: style
		cairo_set_line_join dc/raw 
			case [
				style = miter		[0]
				style = _round		[1]
				style = bevel		[2]
				style = miter-bevel	[0]
				true				[0]
			]
	]
]
	
OS-draw-line-cap: func [
	dc	  [draw-ctx!]
	style [integer!]
	/local
		mode [integer!]
][
	if dc/pen-cap <> style [
		dc/pen-cap: style
		cairo_set_line_cap dc/raw
			case [
				style = flat		[0]
				style = _round		[1]
				style = square		[2]
				true				[0]
			]
	]
]

GDK-draw-image: func [
	cr			[handle!]
	image		[handle!]
	x			[integer!]
	y			[integer!]
	width		[integer!]
	height		[integer!]
	/local
		img		[handle!]
][
	img: either width = 0 [image][gdk_pixbuf_scale_simple image width height 2]
	;; DEBUG: print ["GDK-draw-image: " x "x" y lf]
	cairo_translate cr as-float x as-float y
	gdk_cairo_set_source_pixbuf cr img 0 0
	cairo_paint cr
	cairo_translate cr as-float (0 - x) as-float (0 - y)
]

OS-draw-image: func [
	dc			[draw-ctx!]
	image		[red-image!]
	start		[red-pair!]
	end			[red-pair!]
	key-color	[red-tuple!]
	border?		[logic!]
	crop1		[red-pair!]
	pattern		[red-word!]
	/local
		img		[integer!]
		sub-img [integer!]
		x		[integer!]
		y		[integer!]
		width	[integer!]
		height	[integer!]
		w		[float!]
		h		[float!]
		ww		[float!]
		crop2	[red-pair!]
][
	;; print ["OS-draw-image" lf]
	either null? start [x: 0 y: 0][x: start/x y: start/y]
	case [
		start = end [
			width:  IMAGE_WIDTH(image/size)
			height: IMAGE_HEIGHT(image/size)
		]
		start + 1 = end [					;-- two control points
			width: end/x - x
			height: end/y - y
		]
		start + 2 = end [0]					;@@ TBD three control points
		true [0]							;@@ TBD four control points
	]

	;; DEBUG: print ["OS-draw-image: " x "x" y " " width "x" height lf]

	img: OS-image/to-pixbuf image
	if crop1 <> null [
		crop2: crop1 + 1
		w: as float! crop2/x
		h: as float! crop2/y
		ww: w / h * (as float! height)
		width: as-integer ww
		; create new pixbuf
		sub-img: as-integer gdk_pixbuf_scale_simple as handle! img width height 0 ; to correct parameters!!!
		;sub-img: as-integer gdk_pixbuf_new 0 yes 8 width height
		;gdk_pixbuf_scale as handle! img as handle! sub-img 0 0 width height 0.0 0.0 1.0 1.0 0 ; to correct parameters!!!
	]

	GDK-draw-image dc/raw as handle! img x y width height
	if crop1 <> null [g_object_unref as handle! sub-img]
]

OS-draw-grad-pen-old: func [
	dc			[draw-ctx!]
	type		[integer!]
	mode		[integer!]
	offset		[red-pair!]
	count		[integer!]					;-- number of the colors
	brush?		[logic!]
	/local
		x		[float!]
		y		[float!]
		start	[float!]
		stop	[float!]
		pattern	[handle!]
		int		[red-integer!]
		f		[red-float!]
		head	[red-value!]
		next	[red-value!]
		clr		[red-tuple!]
		n		[integer!]
		delta	[float!]
		p		[float!]
		scale?	[logic!]
][
	x: as-float offset/x
	y: as-float offset/y

	int: as red-integer! offset + 1
	start: as-float int/value
	int: int + 1
	stop: as-float int/value

	pattern: either type = linear [
		cairo_pattern_create_linear x + start y x + stop y
	][
		cairo_pattern_create_radial x y start x y stop
	]

	n: 0
	scale?: no
	y: 1.0
	while [
		int: int + 1
		n < 3
	][								;-- fetch angle, scale-x and scale-y (optional)
		switch TYPE_OF(int) [
			TYPE_INTEGER	[p: as-float int/value]
			TYPE_FLOAT		[f: as red-float! int p: f/value]
			default			[break]
		]
		switch n [
			0	[0]					;-- rotation
			1	[x:	p scale?: yes]
			2	[y:	p]
		]
		n: n + 1
	]

	if scale? [0]

	delta: 1.0 / as-float count - 1
	p: 0.0
	head: as red-value! int
	loop count [
		clr: as red-tuple! either TYPE_OF(head) = TYPE_WORD [_context/get as red-word! head][head]
		next: head + 1
		n: clr/array1
		x: as-float n and FFh
		x: x / 255.0
		y: as-float n >> 8 and FFh
		y: y / 255.0
		start: as-float n >> 16 and FFh
		start: start / 255.0
		stop: as-float 255 - (n >>> 24)
		stop: stop / 255.0
		if TYPE_OF(next) = TYPE_FLOAT [head: next f: as red-float! head p: f/value]
		cairo_pattern_add_color_stop_rgba pattern p x y start stop
		p: p + delta
		head: head + 1
	]

	if brush? [dc/brush?: yes]				;-- set brush, or set pen
	unless null? dc/pattern [cairo_pattern_destroy dc/pattern]
	dc/pattern: pattern
]

OS-draw-grad-pen: func [
	ctx			[draw-ctx!]
	type		[integer!]
	stops		[red-value!]
	count		[integer!]
	skip-pos?	[logic!]
	positions	[red-value!]
	focal?		[logic!]
	spread		[integer!]
	brush?		[logic!]
][
	
]

OS-matrix-rotate: func [
	dc		[draw-ctx!]
	pen		[integer!]
	angle	[red-integer!]
	center	[red-pair!]
	/local
		cr 	[handle!]
		rad [float!]
][
	cr: dc/raw
	rad: PI / 180.0 * get-float angle
	cairo_translate cr as float! center/x 
					   as float! center/y
	cairo_rotate cr rad
	cairo_translate cr as float! (0 - center/x) 
					   as float! (0 - center/y)
]

OS-matrix-scale: func [
	dc		[draw-ctx!]
	pen		[integer!]
	sx		[red-integer!]
	sy		[red-integer!]
	/local
		cr [handle!]
][
	cr: dc/raw
	cairo_scale cr as float! get-float32 sx
				   as float! get-float32 sy
]

OS-matrix-translate: func [
	dc	[draw-ctx!]
	pen	[integer!]
	x	[integer!]
	y	[integer!]
	/local
		cr [handle!]
][
	cr: dc/raw
	cairo_translate cr as-float x 
					   as-float y
]

OS-matrix-skew: func [
	dc		[draw-ctx!]
	pen		[integer!]
	sx		[red-integer!]
	sy		[red-integer!]
	/local
		m	[integer!]
		x	[float32!]
		y	[float32!]
		u	[float32!]
		z	[float32!]
][
	m: 0
	u: as float32! 1.0
	z: as float32! 0.0
	x: as float32! tan degree-to-radians get-float sx TYPE_TANGENT
	y: as float32! either sx = sy [0.0][tan degree-to-radians get-float sy TYPE_TANGENT]
]

OS-matrix-transform: func [
	dc			[draw-ctx!]
	pen			[integer!]
	center		[red-pair!]
	scale		[red-integer!]
	translate	[red-pair!]
	/local
		rotate	[red-integer!]
		center? [logic!]
][
	rotate: as red-integer! either center + 1 = scale [center][center + 1]
	center?: rotate <> center

	OS-matrix-rotate dc pen rotate center
	OS-matrix-scale dc pen scale scale + 1
	OS-matrix-translate dc pen translate/x translate/y
]

OS-matrix-push: func [dc [draw-ctx!] /local state [integer!]][
	state: 0
]

OS-matrix-pop: func [dc [draw-ctx!]][0]

OS-matrix-reset: func [
	dc [draw-ctx!]
	pen [integer!]
	/local
		cr [handle!]
][
	cr: dc/raw
	cairo_identity_matrix cr
]

OS-matrix-invert: func [
	dc	[draw-ctx!]
	pen	[integer!]
][]

OS-matrix-set: func [
	dc		[draw-ctx!]
	pen		[integer!]
	blk		[red-block!]
	/local
		m	[integer!]
		val [red-integer!]
][
	m: 0
	val: as red-integer! block/rs-head blk
]

OS-set-matrix-order: func [
	ctx		[draw-ctx!]
	order	[integer!]
][
	0
]

OS-set-clip: func [
	dc		[draw-ctx!]
	upper	[red-pair!]
	lower	[red-pair!]
][
	0
]

;-- shape sub command --

OS-draw-shape-beginpath: func [
	dc			[draw-ctx!]
][
	cairo_save dc/raw
	cairo_new_path dc/raw 
]

OS-draw-shape-endpath: func [
	dc			[draw-ctx!]
	close?		[logic!]
	return:		[logic!]
][
	if close? [cairo_close_path dc/raw]
	do-paint dc
	cairo_restore dc/raw
	true
]

OS-draw-shape-moveto: func [
	dc		[draw-ctx!]
	coord	[red-pair!]
	rel?	[logic!]
	/local
		x		[float!]
		y		[float!]
][
	x: as-float coord/x
	y: as-float coord/y
	either rel? [
		cairo_rel_move_to dc/raw x y
	][
		cairo_move_to dc/raw x y
	]
	dc/shape-curve?: no
]

OS-draw-shape-line: func [
	dc			[draw-ctx!]
	start		[red-pair!]
	end			[red-pair!]
	rel?		[logic!]
	/local
		x		[float!]
		y		[float!]
][
	until [
		x: as-float start/x
		y: as-float start/y
		either rel? [
			cairo_rel_line_to dc/raw x y
		][
			cairo_line_to dc/raw x y
		]
		start: start + 1
		start > end
	]
	dc/shape-curve?: no
]

OS-draw-shape-axis: func [
	dc			[draw-ctx!]
	start		[red-value!]
	end			[red-value!]
	rel?		[logic!]
	hline?		[logic!]
	/local
		len 	[float!]
		last-x	[float!]
		last-y	[float!]
][
	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point dc/raw[
		cairo_get_current_point dc/raw :last-x :last-y
	]
	len: get-float as red-integer! start
	either hline? [
		cairo_line_to dc/raw either rel? [last-x + len][len] last-y
	][
		cairo_line_to dc/raw last-x either rel? [last-y + len][len]
	]
	dc/shape-curve?: no
]

draw-curve: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
	short?	[logic!]
	num		[integer!]				;--	number of points
	/local
		dx		[float!]
		dy		[float!]
		p3y		[float!]
		p3x		[float!]
		p2y		[float!]
		p2x		[float!]
		p1y		[float!]
		p1x		[float!]
		pf		[float-ptr!]
		pt		[red-pair!]
][
	pt: start + 1
	p1x: as-float start/x
	p1y: as-float start/y
	p2x: as-float pt/x
	p2y: as-float pt/y
	if num = 3 [					;-- cubic Bézier
		pt: start + 2
		p3x: as-float pt/x
		p3y: as-float pt/y
	]

	; dx: dc/last-pt-x
	; dy: dc/last-pt-y
	; if rel? [
	; 	pf: :p1x
	; 	loop num [
	; 		pf/1: pf/1 + dx			;-- x
	; 		pf/2: pf/2 + dy			;-- y
	; 		pf: pf + 2
	; 	]
	; ]

	; if short? [
	; 	either dc/shape-curve? [
	; 		;-- The control point is assumed to be the reflection of the control point
	; 		;-- on the previous command relative to the current point
	; 		p1x: dx * 2.0 - dc/control-x
	; 		p1y: dy * 2.0 - dc/control-y
	; 	][
	; 		;-- if previous command is not curve/curv/qcurve/qcurv, use current point
	; 		p1x: dx
	; 		p1y: dy
	; 	]
	; ]

	dc/shape-curve?: yes
	either num = 3 [				;-- cubic Bézier
		either rel? [cairo_rel_curve_to dc/raw p1x p1y p2x p2y p3x p3y] 
		[cairo_curve_to dc/raw p1x p1y p2x p2y p3x p3y]
		; dc/control-x: p2x
		; dc/control-y: p2y
		; dc/last-pt-x: p3x
		; dc/last-pt-y: p3y
	][								;-- quadratic Bézier
		;CGPathAddQuadCurveToPoint dc/path null p1x p1y p2x p2y
		; dc/control-x: p1x
		; dc/control-y: p1y
		; dc/last-pt-x: p2x
		; dc/last-pt-y: p2y
		0
	]
]


OS-draw-shape-curve: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-curve dc start end rel? no 3
]

OS-draw-shape-qcurve: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-curve dc start end rel? no 2
]

OS-draw-shape-curv: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
	draw-curve dc start - 1 end rel? yes 3
]

OS-draw-shape-qcurv: func [
	dc		[draw-ctx!]
	start	[red-pair!]
	end		[red-pair!]
	rel?	[logic!]
][
		draw-curve dc start - 1 end rel? yes 2
]

OS-draw-shape-arc: func [
	dc		[draw-ctx!]
	end		[red-pair!]
	sweep?	[logic!]
	large?	[logic!]
	rel?	[logic!]
	/local
		ctx			[handle!]
		item		[red-integer!]
		last-x		[float!]
		last-y		[float!]
		center-x	[float32!]
		center-y	[float32!]
		cx			[float32!]
		cy			[float32!]
		cf			[float32!]
		angle-len	[float32!]
		radius-x	[float32!]
		radius-y	[float32!]
		theta		[float32!]
		X1			[float32!]
		Y1			[float32!]
		p1-x		[float32!]
		p1-y		[float32!]
		p2-x		[float32!]
		p2-y		[float32!]
		cos-val		[float32!]
		sin-val		[float32!]
		rx2			[float32!]
		ry2			[float32!]
		dx			[float32!]
		dy			[float32!]
		sqrt-val	[float32!]
		sign		[float32!]
		rad-check	[float32!]
		pi2			[float32!]
][
	last-x: 0.0 last-y: 0.0
	if 1 = cairo_has_current_point dc/raw[
		cairo_get_current_point dc/raw :last-x :last-y
	]
	p1-x: as float32! last-x p1-y: as float32! last-y
	p2-x: either rel? [ p1-x + as float32! end/x ][ as float32! end/x ]
	p2-y: either rel? [ p1-y + as float32! end/y ][ as float32! end/y ]
	item: as red-integer! end + 1
	radius-x: fabsf get-float32 item
	item: item + 1
	radius-y: fabsf get-float32 item
	item: item + 1
	pi2: as float32! 2.0 * PI
	theta: get-float32 item
	theta: theta * as float32! (PI / 180.0)
	theta: theta % pi2

	;-- calculate center
	dx: (p1-x - p2-x) / as float32! 2.0
	dy: (p1-y - p2-y) / as float32! 2.0
	cos-val: cosf theta
	sin-val: sinf theta
	X1: (cos-val * dx) + (sin-val * dy)
	Y1: (cos-val * dy) - (sin-val * dx)
	rx2: radius-x * radius-x
	ry2: radius-y * radius-y
	rad-check: ((X1 * X1) / rx2) + ((Y1 * Y1) / ry2)
	if rad-check > as float32! 1.0 [
		radius-x: radius-x * sqrtf rad-check
		radius-y: radius-y * sqrtf rad-check
		rx2: radius-x * radius-x
		ry2: radius-y * radius-y
	]
	either large? = sweep? [sign: as float32! -1.0 ][sign: as float32! 1.0 ]
	sqrt-val: ((rx2 * ry2) - (rx2 * Y1 * Y1) - (ry2 * X1 * X1)) / ((rx2 * Y1 * Y1) + (ry2 * X1 * X1))
	either sqrt-val < as float32! 0.0 [cf: as float32! 0.0 ][ cf: sign * sqrtf sqrt-val ]
	cx: cf * (radius-x * Y1 / radius-y)
	cy: cf * (radius-y * X1 / radius-x) * (as float32! -1.0)
	center-x: (cos-val * cx) - (sin-val * cy) + ((p1-x + p2-x) / as float32! 2.0)
	center-y: (sin-val * cx) + (cos-val * cy) + ((p1-y + p2-y) / as float32! 2.0)


	;-- transform our ellipse into the unit circle
	; m: CGAffineTransformMakeScale (as float! 1.0) / radius-x (as float! 1.0) / radius-y
	; m: CGAffineTransformRotate m (as float! 0.0) - theta
	; m: CGAffineTransformTranslate m (as float! 0.0) - center-x (as float! 0.0) - center-y

	; pt1/x: p1-x pt1/y: p1-y
	; pt2/x: p2-x pt2/y: p2-y
	; pt1: CGPointApplyAffineTransform pt1 m
	; pt2: CGPointApplyAffineTransform pt2 m

	;-- calculate angles
	cx: atan2f p1-y p1-x
	cy: atan2f p2-y p2-x
	angle-len: cy - cx
	either sweep? [
		if angle-len < as float32! 0.0 [
			angle-len: angle-len + pi2
		]
	][
		if angle-len > as float32! 0.0 [
			angle-len: angle-len - pi2
		]
	]

	;-- construct the inverse transform
	; m: CGAffineTransformMakeTranslation center-x center-y
	; m: CGAffineTransformRotate m theta
	; m: CGAffineTransformScale m radius-x radius-y
	; CGPathAddRelativeArc ctx/path :m as float32! 0.0 as float32! 0.0 as float32! 1.0 cx angle-len
	ctx: dc/raw
	cairo_save ctx
	cairo_new_sub_path ctx
	cairo_translate ctx as float! center-x as float! center-y
	cairo_scale     ctx as float! radius-x as float! radius-y
	cairo_arc ctx 0.0 0.0 1.0 as float! cx as float! cy
	cairo_restore ctx
]

OS-draw-shape-close: func [
	dc		[draw-ctx!]
][cairo_close_path dc/raw ]

OS-draw-brush-bitmap: func [
	ctx		[draw-ctx!]
	img		[red-image!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	brush?	[logic!]
][]

OS-draw-brush-pattern: func [
	dc		[draw-ctx!]
	size	[red-pair!]
	crop-1	[red-pair!]
	crop-2	[red-pair!]
	mode	[red-word!]
	block	[red-block!]
	brush?	[logic!]
][]
