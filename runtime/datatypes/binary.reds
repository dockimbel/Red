Red/System [
	Title:   "Binary! datatype runtime functions"
	Author:  "Qingtian Xie"
	File: 	 %binary.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic & Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

binary: context [
	verbose: 0

	#define BINARY_SKIP_COMMENT [
		if c = as-integer #";" [		;-- skip comment
			until [
				p: p + unit
				len: len - 1
				c: string/get-char p unit
				c = as-integer lf
			]
		]
	]

	debase64: [
		#"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" ;-- 07h
		#"^(40)" #"^(40)" #"^(40)" #"^(80)" #"^(40)" #"^(40)" #"^(80)" #"^(80)" ;-- 0Fh
		#"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" ;-- 17h
		#"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" ;-- 1Fh
		#"^(40)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(40)" ;-- 27h
		#"^(80)" #"^(80)" #"^(80)" #"^(3E)" #"^(80)" #"^(80)" #"^(80)" #"^(3F)" ;-- 2Fh
		#"^(34)" #"^(35)" #"^(36)" #"^(37)" #"^(38)" #"^(39)" #"^(3A)" #"^(3B)" ;-- 37h
		#"^(3C)" #"^(3D)" #"^(80)" #"^(80)" #"^(80)" #"^(00)" #"^(80)" #"^(80)" ;-- 3Fh
		#"^(80)" #"^(00)" #"^(01)" #"^(02)" #"^(03)" #"^(04)" #"^(05)" #"^(06)" ;-- 47h
		#"^(07)" #"^(08)" #"^(09)" #"^(0A)" #"^(0B)" #"^(0C)" #"^(0D)" #"^(0E)" ;-- 4Fh
		#"^(0F)" #"^(10)" #"^(11)" #"^(12)" #"^(13)" #"^(14)" #"^(15)" #"^(16)" ;-- 57h
		#"^(17)" #"^(18)" #"^(19)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" ;-- 5Fh
		#"^(80)" #"^(1A)" #"^(1B)" #"^(1C)" #"^(1D)" #"^(1E)" #"^(1F)" #"^(20)" ;-- 67h
		#"^(21)" #"^(22)" #"^(23)" #"^(24)" #"^(25)" #"^(26)" #"^(27)" #"^(28)" ;-- 6Fh
		#"^(29)" #"^(2A)" #"^(2B)" #"^(2C)" #"^(2D)" #"^(2E)" #"^(2F)" #"^(30)" ;-- 77h
		#"^(31)" #"^(32)" #"^(33)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" #"^(80)" ;-- 7Fh
	]

	enbase64: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

	rs-length?: func [
		bin 	[red-binary!]
		return: [integer!]
	][
		_series/get-length as red-series! bin no
	]
	
	rs-skip: func [
		bin 	[red-binary!]
		len		[integer!]
		return: [logic!]
	][
		_series/rs-skip as red-series! bin len
	]
	
	rs-next: func [
		bin 	[red-binary!]
		return: [logic!]
		/local
			s [series!]
	][
		_series/rs-skip as red-series! bin 1
	]
	
	rs-head: func [
		bin	    [red-binary!]
		return: [byte-ptr!]
		/local
			s [series!]
	][
		s: GET_BUFFER(bin)
		(as byte-ptr! s/offset) + bin/head
	]
	
	rs-tail: func [
		bin	    [red-binary!]
		return: [byte-ptr!]
		/local
			s [series!]
	][
		s: GET_BUFFER(bin)
		as byte-ptr! s/tail
	]

	rs-tail?: func [
		bin	    [red-binary!]
		return: [logic!]
		/local
			s [series!]
	][
		s: GET_BUFFER(bin)
		(as byte-ptr! s/offset) + bin/head >= as byte-ptr! s/tail
	]

	rs-clear: func [
		bin [red-binary!]
		/local
			s [series!]
	][
		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/offset) + bin/head
	]

	rs-append: func [
		bin		[red-binary!]
		data	[byte-ptr!]
		part	[integer!]
		return: [byte-ptr!]
		/local
			s	 [series!]
			p	 [byte-ptr!]
	][
		s: GET_BUFFER(bin)
		p: alloc-tail-unit s part
		copy-memory p data part
		p
	]

	rs-insert: func [
		bin		[red-binary!]
		offset	[integer!]								;-- offset from head in elements
		data	[byte-ptr!]
		part	[integer!]								;-- limit to given length of value
		return: [byte-ptr!]
		/local
			s	  [series!]
			p	  [byte-ptr!]
	][
		s: GET_BUFFER(bin)

		if ((as byte-ptr! s/tail) + part > ((as byte-ptr! s + 1) + s/size)) [
			s: expand-series s 0
		]
		p: (as byte-ptr! s/offset) + bin/head + offset

		move-memory										;-- make space
			p + part
			p
			as-integer (as byte-ptr! s/tail) - p

		s/tail: as cell! (as byte-ptr! s/tail) + part

		copy-memory p data part
		p
	]

	set-value: func [
		p		[byte-ptr!]
		value	[red-value!]
		/local
			char [red-char!]
			data [byte-ptr!]
			int  [integer!]
	][
		switch TYPE_OF(value) [
			TYPE_CHAR
			TYPE_INTEGER [
				char: as red-char! value
				int: char/value
				data: as byte-ptr! :int
				p/value: data/value
			]
			default [fire [TO_ERROR(script invalid-arg) value]]
		]
	]

	push: func [
		bin [red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/push"]]

		copy-cell as red-value! bin stack/push*
	]

	decode-2: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		return:	[node!]
		/local
			s	 [series!]
			c	 [integer!]
			accum [integer!]
			count [integer!]
			node  [node!]
			bin   [byte-ptr!]
	][
		node: alloc-bytes len >> 3
		s: as series! node/value

		bin: as byte-ptr! s/offset
		count: 0
		accum: 0
		until [
			c: string/get-char p unit
			BINARY_SKIP_COMMENT
			if c > as-integer space [
				case [
					c = as-integer #"0" [accum: accum << 1]
					c = as-integer #"1" [accum: accum << 1 + 1]
					true [return null]
				]
				count: count + 1
				if count = 8 [
					bin/value: as byte! accum
					bin: bin + 1
					count: 0
					accum: 0	
				]
			]
			p: p + unit
			len: len - 1
			zero? len
		]
		if positive? count [return null]
		s/tail: as red-value! bin
		node
	]

	decode-64: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		return:	[node!]
		/local
			s	 [series!]
			c	 [integer!]
			val  [integer!]
			accum [integer!]
			count [integer!]
			flip [integer!]
			node [node!]
			bin	 [byte-ptr!]
	][
		node: alloc-bytes len + 3 * 3 / 4
		s: as series! node/value
		bin: as byte-ptr! s/offset
		accum: 0
		count: 0
		flip: 0
		until [
			c: string/get-char p unit
			BINARY_SKIP_COMMENT
			c: c + 1
			val: as-integer debase64/c
			either val < 40h [
				either c <> 62 [		;-- c <> #"="
					accum: accum << 6 + val
					flip: flip + 1
					if flip = 4 [
						bin/1: as-byte accum >> 16
						bin/2: as-byte accum >> 8
						bin/3: as-byte accum
						bin: bin + 3
						accum: 0
						flip: 0
					]
				][						;-- special padding: "="
					p: p + unit
					len: len - 1
					case [
						flip = 3 [
							bin/1: as-byte accum >> 10
							bin/2: as-byte accum >> 2
							bin: bin + 2
							flip: 0
						]
						flip = 2 [
							p: p + unit
							bin/1: as-byte accum >> 4
							bin: bin + 1
							flip: 0
						]
						true [return null]
					]
					break
				]
			][if val = 80h [return null]]

			p: p + unit
			len: len - 1
			len <= 0
		]
		s/tail: as red-value! bin
		node
	]

	decode-16: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		return:	[node!]
		/local
			s	 [series!]
			c	 [integer!]
			hex  [integer!]
			accum [integer!]
			count [integer!]
			table [byte-ptr!]
			bin   [byte-ptr!]
			node  [node!]
	][
		if zero? len [return alloc-bytes 1]

		node: alloc-bytes len >> 1
		s: as series! node/value

		table: string/escape-url-chars
		bin: as byte-ptr! s/offset
		accum: 0
		count: 0
		until [
			c: string/get-char p unit
			BINARY_SKIP_COMMENT
			if c > as-integer space [
				c: c + 1
				hex: as-integer table/c
				if hex > 15 [return null]
				accum: accum << 4 + hex
				if count and 1 = 1 [
					bin/value: as byte! accum
					bin: bin + 1
				]
				count: count + 1
			]
			p: p + unit
			len: len - 1
			zero? len
		]
		s/tail: as red-value! bin
		node
	]

	serialize: func [
		bin		[red-binary!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		mold?	[logic!]
		return: [integer!]
		/local
			s      [series!]
			bytes  [integer!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
			size   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/serialize"]]

		s: GET_BUFFER(bin)
		head: (as byte-ptr! s/offset) + bin/head
		tail: as byte-ptr! s/tail
		size: as-integer tail - head

		string/concatenate-literal buffer "#{"
		bytes: 0
		if size > 30 [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		part: part - 2
		while [head < tail][
			string/concatenate-literal buffer string/byte-to-hex as-integer head/value
			bytes: bytes + 1
			if bytes % 32 = 0 [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			part: part - 2
			if all [OPTION?(arg) part <= 0][return part]
			head: head + 1
		]
		if all [size > 30 bytes % 32 <> 0] [
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
		]
		string/append-char GET_BUFFER(buffer) as-integer #"}"
		part - 1
	]

	make-at: func [
		slot	[red-value!]
		size 	[integer!]								;-- number of bytes to pre-allocate
		return:	[red-binary!]
		/local 
			bin	[red-binary!]
	][
		bin: as red-binary! slot
		bin/header: TYPE_BINARY
		bin/head: 0
		bin/node: alloc-bytes size
		bin
	]

	make-in: func [
		parent 	[red-block!]
		size	[integer!]
		return: [red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bin/make-in"]]
		
		make-at ALLOC_TAIL(parent) size
	]

	load-in: func [
		src		 [byte-ptr!]
		size	 [integer!]
		blk		 [red-block!]
		return:  [red-binary!]
		/local
			slot [red-value!]
			bin  [red-binary!]
			s	 [series!]
	][
		slot: either null = blk [stack/push*][ALLOC_TAIL(blk)]
		bin: make-at slot size
		
		s: GET_BUFFER(bin)
		copy-memory as byte-ptr! s/offset src size
		s/tail: as cell! (as byte-ptr! s/tail) + size
		bin
	]
	
	load: func [
		src		 [byte-ptr!]
		size	 [integer!]
		return:  [red-binary!]
	][
		load-in src size null
	]

	;--- Actions ---
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		return:	[red-binary!]
		/local
			bin	  [red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/make"]]

		bin: as red-binary! string/make proto spec
		set-type as red-value! bin TYPE_BINARY
		bin
	]

	to: func [
		type	[red-datatype!]
		spec	[red-binary!]
		return: [red-value!]
		/local
			str [red-string!]
			ret [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/to"]]

		switch type/value [
			TYPE_STRING [
				spec/node: unicode/load-utf8
							as c-string! binary/rs-head spec
							binary/rs-length? spec
				spec/header: TYPE_STRING
				ret: as red-value! spec
			]
			default [
				fire [TO_ERROR(script bad-to-arg) type spec]
			]
		]
		stack/set-last ret
	]

	form: func [
		bin		[red-binary!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/form"]]
		
		serialize bin buffer no no no arg part no
	]
	
	mold: func [
		bin		[red-binary!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			formed [c-string!]
			s	   [series!]
			unit   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/mold"]]
		
		serialize bin buffer only? all? flat? arg part yes
	]

	compare: func [
		bin1	[red-binary!]
		bin2	[red-binary!]
		op		[integer!]
		return:	[integer!]
		/local
			s1		[series!]
			s2		[series!]
			len1	[integer!]
			len2	[integer!]
			p1		[byte-ptr!]
			p2		[byte-ptr!]
			end		[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/compare"]]

		if TYPE_OF(bin2) <> TYPE_BINARY [RETURN_COMPARE_OTHER]

		if all [
			bin1/node = bin2/node
			bin1/head = bin2/head
			any [op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL]
		][return 0]

		s1: GET_BUFFER(bin1)
		s2: GET_BUFFER(bin2)
		len1: rs-length? bin1
		len2: rs-length? bin2
		end: as byte-ptr! s2/tail

		either len1 <> len2 [							;-- shortcut exit for different sizes
			if any [
				op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL
			][return 1]

			if len2 > len1 [
				end: end - (len2 - len1)
			]
		][
			if zero? len1 [return 0]					;-- shortcut exit for empty binary!
		]

		p1: (as byte-ptr! s1/offset) + bin1/head
		p2: (as byte-ptr! s2/offset) + bin2/head

		while [all [p2 < end p1/1 = p2/1]][
			p1: p1 + 1
			p2: p2 + 1
		]
		if p2 <> end [len1: as-integer p1/1 len2: as-integer p2/1]
		SIGN_COMPARE_RESULT(len1 len2)
	]

	;--- Modifying actions ---

	insert: func [
		bin		 [red-binary!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg	 [red-value!]
		append?	 [logic!]
		return:	 [red-value!]
		/local
			src		  [red-block!]
			cell	  [red-value!]
			limit	  [red-value!]
			int		  [red-integer!]
			char	  [red-char!]
			sp		  [red-binary!]
			data	  [byte-ptr!]
			s		  [series!]
			s2		  [series!]
			int-value [integer!]
			dup-n	  [integer!]
			cnt		  [integer!]
			part	  [integer!]
			len		  [integer!]
			added	  [integer!]
			bytes	  [integer!]
			rest	  [integer!]
			tail?	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/insert"]]

		dup-n: 1
		cnt:   1
		part: -1

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				sp: as red-binary! part-arg
				unless all [
					TYPE_OF(sp) = TYPE_BINARY
					sp/node = bin/node
				][
					fire [TO_ERROR(script invalid-part) part-arg]
				]
				sp/head + 1								;-- /head is 0-based
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
			if negative? cnt [return as red-value! bin]
			dup-n: cnt
		]

		s: GET_BUFFER(bin)
		tail?: any [
			(as-integer s/tail - s/offset) >> (log-b GET_UNIT(s)) = bin/head
			append?
		]

		while [not zero? cnt][							;-- /dup support
			either TYPE_OF(value) = TYPE_BLOCK [		;@@ replace it with: typeset/any-block?
				src: as red-block! value
				s2: GET_BUFFER(src)
				cell:  s2/offset + src/head
				limit: cell + block/rs-length? src
			][
				cell:  value
				limit: value + 1
			]
			bytes: 0
			added: 0
			len: 0
			while [all [cell < limit added <> part]][	;-- multiple values case
				switch TYPE_OF(cell) [
					TYPE_CHAR [
						char: as red-char! cell
						data: as byte-ptr! "0000"
						rest: unicode/cp-to-utf8 char/value data
						added: added + 1
					]
					TYPE_INTEGER [
						int: as red-integer! cell		
						either int/value <= FFh [
							int-value: int/value
							data: as byte-ptr! :int-value
							rest: 1
							added: added + 1
						][
							fire [TO_ERROR(script out-of-range) cell]
						]
					]
					default [
						len: _series/get-length as red-series! cell no
						either positive? part [			;-- /part support
							rest: part - added
							if rest > len [rest: len]
							added: added + rest
						][rest: len]
						either TYPE_OF(cell) = TYPE_BINARY [
							data: rs-head as red-binary! cell						
						][
							data: as byte-ptr! unicode/to-utf8 as red-string! cell :rest
						]
					]
				]
				either tail? [
					rs-append bin data rest
				][
					rs-insert bin bytes data rest
				]
				bytes: bytes + rest
				cell: cell + 1
			]
			cnt: cnt - 1
		]
		unless append? [
			bytes: bytes * dup-n
			bin/head: bin/head + bytes
			s: GET_BUFFER(bin)
			assert (as byte-ptr! s/offset) + (bin/head << (log-b GET_UNIT(s))) <= as byte-ptr! s/tail
		]
		as red-value! bin
	]

	do-math: func [
		type		[math-op!]
		return:		[red-value!]
	][
		stack/arguments
	]

	and~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "binary/and~"]]
		do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "binary/or~"]]
		do-math OP_OR
	]

	xor~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "binary/xor~"]]
		do-math OP_XOR
	]

	complement: func [
		bin		[red-binary!]
		return:	[red-value!]
		/local
			s      [series!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/complement"]]

		s: GET_BUFFER(bin)
		head: (as byte-ptr! s/offset) + bin/head
		tail: as byte-ptr! s/tail

		while [head < tail][
			head/1: not head/1
			head: head + 1
		]
		as red-value! bin
	]

	init: does [
		datatype/register [
			TYPE_BINARY
			TYPE_STRING
			"binary!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			:to
			:form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			:and~
			:complement
			:or~
			:xor~
			;-- Series actions --
			null			;append
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			null			;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			:insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			null			;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			INHERIT_ACTION	;sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]