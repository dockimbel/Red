REBOL [
	Title:   "Information extractor from Red runtime source code"
	Author:  "Nenad Rakocevic"
	File: 	 %libRedRT.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

libRedRT: context [
	funcs: vars: none
	
	set [funcs vars] load-cache %system/utils/libRedRT-exports.r
	user-funcs: tail funcs
		
	imports:	make block!  100
	template:	make string! 100'000
	extras:		make block!  100
	obj-path:	'red/objects
	
	lib-file:	  %libRedRT
	include-file: %libRedRT-include.red
	extras-file:  %libRedRT-extras.r
	defs-file:	  %libRedRT-defs.r
	root-dir:	  %./
	
	get-path: func [file][
		either all [system/version/4 = 3 root-dir/1 = %.][
			file
		][
			root-dir/:file
		]
	]
	
	get-include-file: func [job][
		data: read get-path include-file
		replace/all data "$ROOT-PATH$" form system/script/path
		load data
	]
	
	get-definitions: func [/local data][
		data: load get-path defs-file
		foreach part [1 7 8][
			replace/all data/:part %"" to word! "%"
			replace/all data/:part ">>>" to word! ">>>"
		]
		data
	]
	
	init-extras: does [
		clear extras
		clear user-funcs
	]	
	
	save-extras: has [file][
		unless empty? extras [
			unless encap? [file: join %../ extras-file]
			write get-path extras-file mold/only extras
		]
	]
	
	collect-extra: func [name [word!]][
		if all [
			not find extras name
			find/match form name "red/"
			not find/only funcs path: load form name	;-- funcs contains paths
			not find [get-root get-root-node] path/2
		][
			append extras name
		]	
	]
	
	make-exports: func [functions exports /local name file][
		foreach [name spec] functions [
			if all [
				pos: find/match form name "exec/"
				not find pos slash
			][
				append/only funcs load form name
			]
		]
		if exists? file: get-path extras-file [
			append funcs load file
		]
		foreach def funcs [
			name: to word! form def
			append exports name
			unless select/only functions name [
				print ["*** libRedRT Error: definition not found for" def]
				halt
			]
			system-dialect/compiler/flag-callback name none
		]
		foreach [def type] vars [
			name: to word! form def
			append exports name
		]
	]
	
	obj-to-path: func [list tree /local pos o][
		foreach [sym obj ctx id proto opt] list [
			if 2 < length? obj-path [
				pos: find tree obj
				change/only pos to paren! reduce [append copy obj-path sym]
			]
			if object? obj [
				foreach w next first obj [
					if object? o: get in obj w [
						append obj-path load mold/flat sym	;-- clean-up unwanted newlines hints
						obj-to-path reduce [w o none none none none] tree
						remove back tail obj-path
					]
				]
			]
		]
		tree
	]
	
	process: func [job functions exports /local name list pos tmpl words lits file base-dir][
		make-exports functions exports
		if job/OS = 'Windows [append/only funcs 'red/image/push]
		
		clear imports
		clear template
		append template "^/red: context "
		
		append imports [
			#include %$ROOT-PATH$runtime/definitions.reds
			#include %$ROOT-PATH$runtime/macros.reds
			#include %$ROOT-PATH$runtime/datatypes/structures.reds
				
			cell!: alias struct! [
				header	[integer!]						;-- cell's header flags
				data1	[integer!]						;-- placeholders to make a 128-bit cell
				data2	[integer!]
				data3	[integer!]
			]
			series-buffer!: alias struct! [
				flags	[integer!]						;-- series flags
				node	[int-ptr!]						;-- point back to referring node
				size	[integer!]						;-- usable buffer size (series-buffer! struct excluded)
				offset	[cell!]							;-- series buffer offset pointer (insert at head optimization)
				tail	[cell!]							;-- series buffer tail pointer 
			]
			
			root-base: as cell! 0
			
			get-root: func [
				idx		[integer!]
				return: [red-block!]
			][
				as red-block! root-base + idx
			]
			
			get-root-node: func [
				idx		[integer!]
				return: [node!]
				/local
					obj [red-object!]
			][
				obj: as red-object! get-root idx
				obj/ctx
			]

		]
		foreach def funcs [
			ctx: next def
			list: imports
			
			while [not tail? next ctx][
				unless pos: find list name: to set-word! ctx/1 [
					pos: tail list
					repend list [
						name 'context
						make block! 10
					]
					new-line skip tail list -3 yes
				]
				list: pos/3
				ctx: next ctx
			]
			either pos: find list #import [pos: pos/2/3][
				append list copy/deep [
					#import [libRedRT-file stdcall]
				]
				append/only last list pos: make block! 20
			]
			name: last ctx
			append pos to set-word! name
			new-line back tail pos yes
			name: to word! form def
			append pos mold name
			
			spec: copy/deep functions/:name/4
			clear find spec /local
			append/only pos spec
		]
		
		foreach [def type] vars [
			list: either 2 < length? def [
				pos: find imports to set-word! def/2
				pos/3/2/3
			][
				pos: find imports #import
				pos/2/3
			]
			repend list [
				to set-word! last def form def reduce [type]
			]
			new-line skip tail list -3 yes
		]
		list: find imports to set-word! 'stack
		append list/3 [
			#enum flags! [FRAME_FUNCTION: 16777216]				;-- 01000000h
		]
		append imports [
			words: context [
				_body:		red/word/load "<body>"
				_anon:		red/word/load "<anon>"
				_remove:	red/word/load "remove"
				_take:		red/word/load "take"
				_clear:		red/word/load "clear"
				_insert:	red/word/load "insert"
				_poke:		red/word/load "poke"
				_put:		red/word/load "put"
				_moved:		red/word/load "moved"
				_changed:	red/word/load "changed"
				_reverse:	red/word/load "reverse"
				
				type:		red/symbol/make "type"
				face:	 	red/symbol/make "face"
				window:	 	red/symbol/make "window"
				offset:	 	red/symbol/make "offset"
				key:		red/symbol/make "key"
				picked:		red/symbol/make "picked"
				flags:	 	red/symbol/make "flags"
				away?:		red/symbol/make "away?"
				down?:		red/symbol/make "down?"
				mid-down?:	red/symbol/make "mid-down?"
				alt-down?:	red/symbol/make "alt-down?"
				aux-down?:	red/symbol/make "aux-down?"
				ctrl?:		red/symbol/make "ctrl?"
				shift?:	 	red/symbol/make "shift?"
			]
		]
		
		append template mold imports
		tmpl: load replace/all mold template "[red/" "["
		
		file: get-path include-file
		unless encap? [file: join %../ file]
		write clean-path file tmpl
		
		words: to-block extract red/symbols 2
		remove-each w words [find form w #"~"]
		
		lits: copy red/literals
		while [pos: find lits 'get-root][
			remove/part skip pos -3 5
		]
		replace/all lits 'get-root-node 'get-root-node2
		
		tmpl: mold/all reduce [
			new-line/all/skip to-block red/functions yes 2
			red/redbin/index
			red/globals
			obj-to-path list: copy/deep red/objects list
			red/contexts
			red/actions
			red/op-actions
			words
			lits
			red/s-counter
			red/needed
		]
		replace/all tmpl "% " {%"" }
		replace/all tmpl ">>>" {">>>"}
		replace/all tmpl "red/red-" "red-"

		file: get-path defs-file
		unless encap? [file: join %../ file]
		write clean-path file tmpl
	]
	
]