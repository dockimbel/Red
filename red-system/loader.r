REBOL [
	Title:   "Red/System source program loader"
	Author:  "Nenad Rakocevic"
	File: 	 %loader.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

loader: context [
	verbose: 	  0
	include-dirs: none
	include-list: make hash! 20
	defs:		  make block! 100

	hex-chars: 	  charset "0123456789ABCDEF"
	ws-chars: 	  charset " ^M^-"
	ws-all:		  union ws-chars charset "^/"
	hex-delim: 	  charset "[]()/"
	non-cbracket: complement charset "}^/"

	current-script: none
	line: none

	throw-error: func [err [string! block!]][
		print [
			"*** Loading Error:"
			either word? err [
				join uppercase/part mold err 1 " error"
			][reform err]
			"^/*** in file:" mold current-script
			"^/*** at line:" line
		]
		compiler/quit-on-error
	]

	init: does [
		include-dirs: reduce [runtime-path]
		clear include-list
		clear defs
		insert defs <no-match>					;-- required to avoid empty rule (causes infinite loop)
	]

	included?: func [file [file!]][
		file: get-modes file 'full-path
		either find include-list file [true][
			append include-list file
			false
		]
	]

	find-path: func [file [file!]][
		either slash = first file [
			if exists? file [return file] 		;-- absolute path check
		][
			foreach dir include-dirs [			;-- relative path check using known directories
				if exists? dir/:file [return dir/:file]
			]
		]
		throw-error ["include file access error:" mold file]
	]

	check-marker: func [src [string!] /local pos][
		unless parse/all src [any ws-all "Red/System" any ws-all #"[" to end][
			throw-error "not a Red/System source program"
		]
	]

	check-condition: func [type [word!] payload [block!]][
		if any [
			not any [word? payload/1 lit-word? payload/1]
			not in job payload/1
			all [type <> 'switch not find [= <> < > <= >=] payload/2]
		][
			throw-error rejoin ["invalid #" type " condition"]
		]
		either type = 'switch [
			any [
				select payload/2 job/(payload/1)
				select payload/2 #default
			]
		][
			do bind copy/part payload 3 job
		]
	]

	expand-string: func [src [string! binary!] /local value s e c lf-count ws i prev ins?][
		if verbose > 0 [print "running string preprocessor..."]

		line: 1										;-- lines counter
		lf-count: [lf s: (
			if prev <> i: index? s [				;-- workaround to avoid writing more complex rules
				prev: i
				line: line + 1
				if ins? [s: insert s rejoin [" #L " line " "]]
			]
		)] 
		ws:	[ws-chars | (ins?: yes) lf-count]

		parse/all/case src [						;-- not-LOAD-able syntax support
			any [
				(c: 0)
				#";" to lf
				| {"} thru {"}
				| "{" any [(ins?: no) lf-count | non-cbracket] "}"
				| ws s: ">>>" e: ws (
					e: change/part s "-**" e		;-- convert >>> to -**
				) :e
				| ws s: #"%" e: ws (
					e: change/part s "///" e		;-- convert % to ///
				) :e
				| [hex-delim | ws]
				s: copy value some [hex-chars (c: c + 1)] #"h"	;-- literal hexadecimal support	
				e: [hex-delim | ws-all | #";" to lf | end] (
					either find [2 4 8] c [
						e: change/part s to integer! to issue! value e
					][
						throw-error ["invalid hex literal:" copy/part s 40]
					]
				) :e
				| (ins?: yes) lf-count
				| skip
			]
		]
	]

	expand-block: func [
		src [block!]
		/local blk rule name value s e opr then-block else-block cases body
			saved stack header mark idx prev enum-value enum-name enum-names line-rule
	][
		if verbose > 0 [print "running block preprocessor..."]
		stack: append/only clear [] make block! 100
		append stack/1 1							;-- insert root header starting size
		line: 1

		store-line: [			
			header: last stack				
			idx: index? s
			mark: to pair! reduce [line idx]
			either all [
				prev: pick tail header -1
				pair? prev
				prev/2 = idx 						;-- test if previous marker is at the same series position
			][
				change back tail header mark		;-- replace last marker by a more accurate one
			][			
				append header mark					;-- append line marker to header
			]
		]
		line-rule: [
			s: #L set line integer! e: (
				s: remove/part s 2
				new-line s yes
				do store-line
			) :s
		]
		parse/case src blk: [
			s: (do store-line)
			some [
				defs								;-- resolve definitions in a single pass
				| s: #define set name word! set value skip e: (
					compiler/check-enum-word/by-loader name
					if verbose > 0 [print [mold name #":" mold value]]
					append compiler/definitions name
					if word? value [value: to lit-word! value]
					either block? value [
						saved: reduce [s e]
						parse/case value rule: [
							some [defs | into rule | skip] 	;-- resolve macros recursively
						]
						set [s e] saved
						rule: copy/deep [s: _ e: (e: change/part s copy/deep _ e) :s]
						rule/4/5: :value
					][
						rule: copy/deep [s: _ e: (e: change/part s _ e) :s]
						rule/4/4: :value
					]
					rule/2: to lit-word! name

					either tag? defs/1 [remove defs][append defs '|]
					append defs rule
					remove/part s e
				) :s
				| s: #enum set name word! set value skip e: (
					either block? value [
						saved: reduce [s e]
						compiler/check-enum-word/by-loader name ;-- first checking enumeration identifier possible conflicts
						parse value [
							(enum-value: 0)
							any [
								any line-rule [
									[
										copy enum-names word! |
										(enum-names: make block! 10)
										some [
											set enum-name set-word! any line-rule (append enum-names to word! enum-name)
										]	set enum-value [integer! | word!]
									] (
										enum-value: compiler/set-enumerator name enum-names enum-value
									)
									|
									set enum-name 1 skip (
										throw-error ["invalid enumeration:" to-word enum-name]
									)
								]
							]
						]
						set [s e] saved
					][
						throw-error ["invalid enumeration (block required!):" mold value]
					]
					remove/part s e
				) :s
				| s: #include set name file! e: (
					either included? name: find-path name [
						s: remove/part s e			;-- already included, drop it
					][
						if verbose > 0 [print ["...including file:" mold name]]
						value: skip process/short name 2			;-- skip Red/System header
						e: change/part s value e
						insert e reduce [			;-- put back the parent origin
							#script current-script
						]
						insert s reduce [			;-- mark code origin	
							#script name
						]
						current-script: name
					]
				) :s
				| s: #if set name word! set opr skip set value any-type! set then-block block! e: (
					either check-condition 'if reduce [name opr get/any 'value][
						change/part s then-block e
					][
						remove/part s e
					]
				) :s
				| s: #either set name word! set opr skip set value any-type! set then-block block! set else-block block! e: (
					either check-condition 'either reduce [name opr get/any 'value][
						change/part s then-block e
					][
						change/part s else-block e
					]
				) :s
				| s: #switch set name word! set cases block! e: (
					if body: check-condition 'switch reduce [name cases][
						change/part s body e
					]
				) :s
				| line-rule
				| path! | set-path!	| any-string!		;-- avoid diving into these series
				| s: (if any [block? s/1 paren? s/1][append/only stack copy [1]])
				  [into blk | block! | paren!]			;-- black magic...
				  s: (
					if any [block? s/-1 paren? s/-1][
						header: last stack
						change header length? header	;-- update header size					  		
						s/-1: insert s/-1 header		;-- insert hidden header
						remove back tail stack
					]
				  )
				| skip
			]
		]		
		change stack/1 length? stack/1				;-- update root header size	
		insert src stack/1							;-- return source with hidden root header
	]

	process: func [input [file! string!] /short /local src err path][
		if verbose > 0 [print ["processing" mold either file? input [input]['in-memory]]]

		if file? input [
			if all [
				%./ <> path: first split-path input	;-- is there a path in the filename?
				not find include-dirs path
			][
				insert include-dirs path			;-- register source's dir as include dir
			]
			if error? set/any 'err try [src: as-string read/binary input][	;-- read source file
				throw-error ["file access error:" mold disarm err]
			]
		]
		unless short [
			current-script: pick reduce [input 'in-memory] file? input
		]
		src: any [src input]						;-- process string-level compiler directives
		if file? input [check-marker src]			;-- look for "Red/System" head marker
		expand-string src

		if error? set/any 'err try [src: load src][	;-- convert source to blocks
			throw-error ["syntax error during LOAD phase:" mold disarm err]
		]

		unless short [src: expand-block src]		;-- process block-level compiler directives
		src
	]
]