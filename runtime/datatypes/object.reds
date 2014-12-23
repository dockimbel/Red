Red/System [
	Title:   "Object! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %object.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

object: context [
	verbose: 0
	
	class-id: 1'000'000									;-- base ID for dynamically created objects
	
	get-new-id: func [return: [integer!]][				;@@ protect from concurrent accesses
		class-id: class-id + 1
		class-id
	]
	
	save-self-object: func [
		obj		[red-object!]
		return: [node!]
		/local
			int	 [red-integer!]
			node [node!]
			s	 [series!]
	][
		node: alloc-cells 1								;-- hidden object value storage used by SELF
		s: as series! node/value
		copy-cell as red-value! obj s/offset
		node
	]
	
	make-callback-node: func [
		ctx		[red-context!]
		index   [integer!]
		locals  [integer!]
		return: [node!]
		/local
			node [node!]
			int  [red-integer!]
			s	 [series!]
	][
		node: alloc-cells 2
		s: as series! node/value
		int: as red-integer! s/offset
		int/header: TYPE_INTEGER
		int/value: index

		int: as red-integer! s/offset + 1
		int/header: TYPE_INTEGER
		s: as series! ctx/values/value
		int/value: locals
		node
	]
	
	on-set-defined?: func [
		ctx		[red-context!]
		return: [node!]
		/local
			head   [red-word!]
			tail   [red-word!]
			word   [red-word!]
			fun	   [red-function!]
			s	   [series!]
			on-set [integer!]
			index  [integer!]
	][
		s:		as series! ctx/symbols/value
		head:	as red-word! s/offset
		tail:	as red-word! s/tail
		word:	head
		on-set:	words/_on-change*/symbol
		index:	-1
		
		while [all [index < 0 word < tail]][
			if on-set = symbol/resolve word/symbol [
				index: (as-integer word - head) >> 4
			]
			word: word + 1
		]
		if index = -1 [return null]						;-- callback is not found
		
		s: as series! ctx/values/value
		fun: as red-function! s/offset + index
		
		make-callback-node
			ctx
			index
			_function/calc-arity null fun 0				;-- passing a null path triggers short code branch
	]
	
	fire-on-set*: func [								;-- compiled code entry point
		parent [red-word!]
		field  [red-word!]
	][
		fire-on-set
			as red-object! _context/get parent
			field
			stack/top - 1
			stack/top - 2
	]
	
	fire-on-set: func [
		obj	 [red-object!]
		word [red-word!]
		old	 [red-value!]
		new	 [red-value!]
		/local
			fun	  [red-function!]
			int	  [red-integer!]
			index [integer!]
			count [integer!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/fire-on-set"]]
		
		assert TYPE_OF(obj) = TYPE_OBJECT
		assert obj/on-set <> null
		s: as series! obj/on-set/value
		
		int: as red-integer! s/offset
		assert TYPE_OF(int) = TYPE_INTEGER
		index: int/value
		
		int: as red-integer! s/offset + 1
		assert TYPE_OF(int) = TYPE_INTEGER
		count: int/value
		
		ctx: GET_CTX(obj) 
		s: as series! ctx/values/value
		fun: as red-function! s/offset + index
		assert TYPE_OF(fun) = TYPE_FUNCTION
		
		stack/mark-func words/_on-change*
		stack/push as red-value! word
		stack/push old
		stack/push new
		if positive? count [_function/init-locals count]
		_function/call fun obj/ctx
		stack/unwind
	]
	
	unchanged?: func [
		word	[red-word!]
		id		[integer!]
		return: [logic!]
		/local
			obj [red-object!]
	][
		obj: as red-object! _context/get word
		all [
			TYPE_OF(obj) = TYPE_OBJECT
			obj/class = id
		]
	]
	
	unchanged2?: func [
		node	[node!]
		index	[integer!]
		id		[integer!]
		return: [logic!]
		/local
			obj	   [red-object!]
			ctx	   [red-context!]
			values [series!]
	][
		ctx: TO_CTX(node)
		values: as series! ctx/values/value
		obj: as red-object! values/offset + index
		all [
			TYPE_OF(obj) = TYPE_OBJECT
			obj/class = id
		]
	]
	
	do-indent: func [
		buffer	[red-string!]
		tabs	[integer!]
		part	[integer!]
		return:	[integer!]
		/local
			n [integer!]
	][
		n: tabs
		until [
			string/concatenate-literal buffer "    "
			n: n - 1
			zero? n
		]
		part - (4 * tabs)
	]
	
	serialize: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent?	[logic!]
		tabs	[integer!]
		return: [integer!]
		/local
			ctx		[red-context!]
			syms	[series!]
			values	[series!]
			sym		[red-value!]
			s-tail	[red-value!]
			value	[red-value!]
			blank	[byte!]
	][
		ctx: 	GET_CTX(obj)
		syms:   as series! ctx/symbols/value
		values: as series! ctx/values/value
		
		sym:	syms/offset
		s-tail: syms/tail
		value: 	values/offset
		
		if sym = s-tail [return part]					;-- exit if empty

		either flat? [
			indent?: no
			blank: space
		][
			string/append-char GET_BUFFER(buffer) as-integer lf
			part: part - 1
			blank: lf
		]
		
		while [sym < s-tail][
			if indent? [part: do-indent buffer tabs part]
			
			part: word/mold as red-word! sym buffer no no flat? arg part tabs
			string/concatenate-literal buffer ": "
			part: part - 2
			
			if TYPE_OF(value) = TYPE_VALUE [value/header: TYPE_UNSET] ;-- force uninitialized slot to UNSET
			if TYPE_OF(value) = TYPE_WORD [
				string/append-char GET_BUFFER(buffer) as-integer #"'" ;-- create a literal word
				part: part - 1
			]
			part: actions/mold value buffer only? all? flat? arg part tabs
			
			if any [indent? sym + 1 < s-tail][			;-- no final LF when FORMed
				string/append-char GET_BUFFER(buffer) as-integer blank
				part: part - 1
			]
			sym: sym + 1
			value: value + 1
		]
		part
	]
	
	transfer: func [
		src    [node!]									;-- src context
		dst	   [node!]									;-- dst context (extension of src)
		/local
			from   [red-context!]
			to	   [red-context!]
			word   [red-word!]
			symbol [red-value!]
			value  [red-value!]
			tail   [red-value!]
			target [red-value!]
			s	   [series!]
			idx	   [integer!]
			type   [integer!]
	][
		from: TO_CTX(src)
		to:	  TO_CTX(dst)

		s: as series! from/symbols/value
		symbol: s/offset
		tail: s/tail
		
		s: as series! from/values/value
		value: s/offset

		s: as series! to/values/value
		target: s/offset

		while [symbol < tail][
			word: as red-word! symbol
			idx: _context/find-word to word/symbol no
			
			type: TYPE_OF(value)
			either ANY_SERIES?(type) [					;-- copy series value in extended object
				actions/copy
					as red-series! value
					target + idx
					null
					yes
					null
			][
				copy-cell value target + idx			;-- just propagate the old value by default
			]
			symbol: symbol + 1
			value: value + 1
		]
	]
	
	duplicate: func [
		src    [node!]									;-- src context
		dst	   [node!]									;-- dst context (extension of src)
		/local
			from   [red-context!]
			to	   [red-context!]
			value  [red-value!]
			tail   [red-value!]
			target [red-value!]
			s	   [series!]
			type   [integer!]
	][
		from: TO_CTX(src)
		to:	  TO_CTX(dst)
		
		s: as series! from/values/value
		value: s/offset
		tail:  s/tail
		
		s: as series! to/values/value
		target: s/offset
		
		while [value < tail][
			type: TYPE_OF(value)
			either ANY_SERIES?(type) [					;-- copy series value in extended object
				actions/copy
					as red-series! value
					target
					null
					yes
					null
			][
				copy-cell value target					;-- just propagate the old value by default
			]
			value: value + 1
			target: target + 1
		]
	]
	
	extend: func [
		ctx		[red-context!]
		spec	[red-context!]
		return: [logic!]
		/local
			syms  [red-value!]
			tail  [red-value!]
			vals  [red-value!]
			value [red-value!]
			base  [red-value!]
			word  [red-word!]
			type  [integer!]
			s	  [series!]
	][
		s: as series! spec/symbols/value
		syms: s/offset
		tail: s/tail

		s: as series! spec/values/value
		vals: s/offset
		
		s: as series! ctx/symbols/value
		base: s/tail - s/offset
		
		s: as series! ctx/values/value

		while [syms < tail][
			value: _context/add-with ctx as red-word! syms vals
			
			if null? value [
				word: as red-word! syms
				value: s/offset + _context/find-word ctx word/symbol no
				copy-cell vals value
			]
			type: TYPE_OF(value)
			case [
				ANY_SERIES?(type) [
					actions/copy
						as red-series! value
						value						;-- overwrite the value
						null
						yes
						null
				]
				type = TYPE_FUNCTION [
					rebind as red-function! value ctx
				]
				true [0]
			]
			syms: syms + 1
			vals: vals + 1
		]
		s: as series! ctx/symbols/value					;-- refreshing pointer
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	rebind: func [
		fun		[red-function!]
		ctx 	[red-context!]
		/local
			s	 [series!]
			more [red-value!]
			blk  [red-block!]
			spec [red-block!]
	][
		s: as series! fun/more/value
		more: s/offset
		
		if TYPE_OF(more) = TYPE_NONE [
			print-line "*** Error: rebinding stuck on missing function's body block"
			halt
		]
		spec: as red-block! stack/push*
		spec/head: 0
		spec/node: fun/spec
		
		blk: block/clone as red-block! more yes
		_context/bind blk ctx null yes					;-- rebind new body to object
		_function/push spec blk	fun/ctx null null		;-- recreate function
		copy-cell stack/top - 1	as red-value! fun		;-- overwrite function slot in object
		stack/pop 2										;-- remove extra stack slots (block/clone and _function/push)
		
		s: as series! fun/more/value
		more: s/offset + 2
		more/header: TYPE_UNSET							;-- invalidate compiled body
	]
	
	init-push: func [
		node	[node!]
		class	[integer!]
		return: [red-object!]
		/local
			ctx [red-context!]
			obj	[red-object!]
	][
		ctx: TO_CTX(node)
		s: as series! ctx/values/value
		if s/offset = s/tail [
			s/tail: s/offset + (s/size >> 4)			;-- (late) setting of 'values right tail pointer
		]
		
		obj: as red-object! stack/push*
		obj/header: TYPE_OBJECT
		obj/ctx:	node
		obj/class:	class
		obj/on-set: null								;-- deferred setting, once object's body is evaluated
		obj
	]
	
	init-on-set: func [
		ctx	   [node!]
		index  [integer!]
		locals [integer!]
		/local
			obj [red-object!]
	][
		obj: as red-object! stack/top - 1
		assert TYPE_OF(obj) = TYPE_OBJECT
		obj/on-set: make-callback-node TO_CTX(ctx) index locals
	]
	
	push: func [
		ctx		[node!]
		class	[integer!]
		index	[integer!]
		locals	[integer!]
		return: [red-object!]
		/local
			obj	[red-object!]
	][
		obj: as red-object! stack/push*
		obj/header: TYPE_OBJECT
		obj/ctx:	ctx
		obj/class:	class
		obj/on-set: make-callback-node TO_CTX(ctx) index locals
		obj
	]
	
	make-at: func [
		obj		[red-object!]
		slots	[integer!]
		return: [red-object!]
	][
		obj/header: TYPE_OBJECT
		obj/ctx:	_context/create slots no yes
		obj/class:	0
		obj/on-set: null
		obj
	]
	
	collect-couples: func [
		ctx	 	[red-context!]
		spec 	[red-block!]
		only?	[logic!]
		return: [logic!]
		/local
			cell   [red-value!]
			tail   [red-value!]
			value  [red-value!]
			values [red-value!]
			base   [red-value!]
			word   [red-word!]
			s	   [series!]
			id	   [integer!]
			sym	   [integer!]
	][
		s: GET_BUFFER(spec)
		cell: s/offset
		tail: s/tail

		s: as series! ctx/symbols/value
		base: s/tail - s/offset
		
		s: as series! ctx/values/value
		values: s/offset
		
		while [cell < tail][
			if TYPE_OF(cell) = TYPE_SET_WORD [
				id: _context/add ctx as red-word! cell

				value: cell + 1							;-- fetch next value to assign
				while [all [
					TYPE_OF(value) = TYPE_SET_WORD
					value < tail
				]][
					value: value + 1
				]
				if value = tail [value: as red-value! none-value]
				
				if all [not only? TYPE_OF(value) = TYPE_WORD][ ;-- reduce the value if allowed
					word: as red-word! value
					sym: symbol/resolve word/symbol
					if any [
						sym = words/_true
						sym = words/_yes
						sym = words/_on
					][
						value: as red-value! true-value
					]
					if any [
						sym = words/_false
						sym = words/_no
						sym = words/_off
					][
						value: as red-value! false-value
					]
					if sym = words/none [value: as red-value! none-value]
				]
				
				copy-cell value values + id
			]
			cell: cell + 1
		]
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	construct: func [
		spec	[red-block!]
		proto	[red-object!]
		only?	[logic!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
			ctx	 [red-context!]
	][
		obj: as red-object! stack/push*
		make-at obj 4								;-- arbitrary value
		ctx: GET_CTX(obj)
		unless null? proto [extend ctx GET_CTX(proto)]
		collect-couples ctx spec only?
		obj/class: get-new-id
		obj/on-set: null
		obj
	]
	
	;-- Actions --
	
	make: func [
		proto	[red-object!]
		spec	[red-value!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
			obj2 [red-object!]
			ctx	 [red-context!]
			blk	 [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/make"]]
		
		obj: as red-object! stack/push*
		
		either TYPE_OF(proto) = TYPE_OBJECT [
			copy proto obj null yes null				;-- /deep
		][
			make-at obj 4								;-- arbitrary value
		]
		ctx: GET_CTX(obj)
		
		switch TYPE_OF(spec) [
			TYPE_OBJECT [
				obj2: as red-object! spec
				obj/class: either extend ctx GET_CTX(obj2) [get-new-id][proto/class]
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				_context/collect-set-words ctx blk
				_context/bind blk ctx save-self-object obj yes
				interpreter/eval blk no
				obj/class: get-new-id
				obj/on-set: on-set-defined? ctx
			]
			default [
				print-line "*** Error: invalid spec value for object construction"
				halt
			]
		]
		obj
	]
	
	reflect: func [
		obj		[red-object!]
		field	[integer!]
		return:	[red-block!]
		/local
			ctx	  [red-context!]
			blk   [red-block!]
			syms  [red-value!]
			vals  [red-value!]
			tail  [red-value!]
			value [red-value!]
			s	  [series!]
	][
		blk: 		as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 	0
		
		ctx: GET_CTX(obj)
		
		case [
			field = words/words [
				blk/node: ctx/symbols
				blk: block/clone blk no
			]
			field = words/values [
				blk/node: ctx/values
				blk: block/clone blk no
			]
			field = words/body [
				blk/node: ctx/symbols
				blk/node: alloc-cells block/rs-length? blk
				
				s: as series! ctx/symbols/value
				syms: s/offset
				tail: s/tail
				
				s: as series! ctx/values/value
				vals: s/offset
				
				while [syms < tail][
					value: block/rs-append blk syms
					value/header: TYPE_SET_WORD
					block/rs-append blk vals
					syms: syms + 1
					vals: vals + 1
				]
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		as red-block! stack/set-last as red-value! blk
	]
	
	form: func [
		obj		[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/form"]]

		serialize obj buffer no no no arg part no 0
	]
	
	mold: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/mold"]]
		
		string/concatenate-literal buffer "make object! ["
		part: serialize obj buffer only? all? flat? arg part - 14 yes indent + 1
		if indent > 0 [part: do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	eval-path: func [
		parent	[red-object!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		return:	[red-value!]
		/local
			word	[red-word!]
			ctx		[red-context!]
			old		[red-value!]
			on-set? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/eval-path"]]
		
		word: as red-word! element
		assert TYPE_OF(word) = TYPE_WORD
		ctx:  GET_CTX(parent)

		if word/ctx <> parent/ctx [						;-- bind the word to object's context
			word/index: _context/find-word ctx word/symbol no
			word/ctx: parent/ctx
		]
		either value <> null [
			on-set?: parent/on-set <> null
			if on-set? [old: stack/push _context/get-in word ctx]
			_context/set-in word value ctx
			if on-set? [fire-on-set parent as red-word! element old value]
			value
		][
			_context/get-in word ctx
		]
	]
	
	compare: func [
		obj1	[red-object!]							;-- first operand
		obj2	[red-object!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[logic!]
		/local
			ctx1   [red-context!]
			ctx2   [red-context!]
			sym1   [red-word!]
			sym2   [red-word!]
			tail   [red-word!]
			value1 [red-value!]
			value2 [red-value!]
			s	   [series!]
			diff   [integer!]
			s1	   [integer!]
			s2	   [integer!]
			type1  [integer!]
			type2  [integer!]
			res	   [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/compare"]]

		if TYPE_OF(obj2) <> TYPE_OBJECT [RETURN_COMPARE_OTHER]
		
		ctx1: GET_CTX(obj1)
		s: as series! ctx1/symbols/value
		sym1: as red-word! s/offset
		tail: as red-word! s/tail
		
		ctx2: GET_CTX(obj2)
		s: as series! ctx2/symbols/value
		
		diff: (as-integer s/tail - s/offset) - (as-integer tail - sym1)
		if diff <> 0 [
			switch op [
				COMP_EQUAL
				COMP_STRICT_EQUAL  [res: false]
				COMP_NOT_EQUAL 	   [res: true]
				COMP_LESSER
				COMP_LESSER_EQUAL  [res: diff > 0]
				COMP_GREATER
				COMP_GREATER_EQUAL [res: diff < 0]
			]
			return res
		]	
		if zero? (as-integer tail - sym1) [			;-- empty objects case
			switch op [
				COMP_EQUAL
				COMP_STRICT_EQUAL
				COMP_LESSER_EQUAL
				COMP_GREATER_EQUAL [res: true]
				COMP_NOT_EQUAL 	   [res: false]
				default 		   [res: false]
			]
			return res
		]
		
		sym2: as red-word! s/offset
		s: as series! ctx1/values/value
		value1: s/offset
		s: as series! ctx2/values/value
		value2: s/offset
		
		until [
			s1: symbol/resolve sym1/symbol
			s2: symbol/resolve sym2/symbol
			if s1 <> s2 [
				switch op [
					COMP_EQUAL
					COMP_STRICT_EQUAL  [res: false]
					COMP_NOT_EQUAL 	   [res: true]
					COMP_LESSER
					COMP_LESSER_EQUAL  [res: s1 < s2]
					COMP_GREATER
					COMP_GREATER_EQUAL [res: s1 > s2]
				]
				return res
			]
			type1: TYPE_OF(value1)
			type2: TYPE_OF(value2)
			either any [
				type1 = type2
				all [word/any-word? type1 word/any-word? type2]
				all [type1 = TYPE_INTEGER type2 = TYPE_INTEGER]	 ;@@ replace by ANY_NUMBER?
			][
				res: actions/compare value1 value2 op
				sym1: sym1 + 1
				sym2: sym2 + 2
				value1: value1 + 1
				value2: value2 + 1
			][
				switch op [
					COMP_EQUAL
					COMP_STRICT_EQUAL	[res: false]
					COMP_NOT_EQUAL 		[res: true]
					COMP_LESSER_EQUAL	[res: type1 <= type2]
					COMP_GREATER_EQUAL	[res: type1 >= type2]
				]
				return res
			]
			any [
				not res
				sym1 >= tail
			]
		]
		res
	]
	
	copy: func [
		obj      [red-object!]
		new	  	 [red-object!]
		part-arg [red-value!]
		deep?	 [logic!]
		types	 [red-value!]
		return:	 [red-object!]
		/local
			ctx	  [red-context!]
			nctx  [red-context!]
			value [red-value!]
			tail  [red-value!]
			src	  [series!]
			dst	  [series!]
			size  [integer!]
			slots [integer!]
			type  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/copy"]]
		
		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			print-line "***Error: copy/part is not supported on objects"
			halt
		]

		ctx:	GET_CTX(obj)
		src:	as series! ctx/symbols/value
		size:   as-integer src/tail - src/offset
		slots:	size >> 4
		
		new: make-at new slots
		new/class: obj/class
		nctx: GET_CTX(new)
		
		;-- process SYMBOLS
		dst: as series! nctx/symbols/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/size: size
		dst/tail: dst/offset + slots
		_context/set-context-each dst new/ctx
		
		;-- process VALUES
		src: as series! ctx/values/value
		dst: as series! nctx/values/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/size: size
		dst/tail: dst/offset + slots
		
		value: dst/offset
		tail:  dst/tail
		
		either deep? [
			while [value < tail][
				type: TYPE_OF(value)
				case [
					ANY_SERIES?(type) [
						actions/copy 
							as red-series! value
							value						;-- overwrite the value
							null
							yes
							null
					]
					type = TYPE_FUNCTION [
						rebind as red-function! value nctx
					]
					true [0]
				]
				value: value + 1
			]
		][
			while [value < tail][
				if TYPE_OF(value) = TYPE_FUNCTION [
					rebind as red-function! value nctx
				]
				value: value + 1
			]
		]
		new
	]
	
	find: func [
		obj		 [red-object!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		tail?	 [logic!]
		match?	 [logic!]
		return:	 [red-value!]
		/local
			word [red-word!]
			ctx	 [node!]
			id	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/find"]]
		
		assert any [									;@@ replace with ANY_WORD?
			TYPE_OF(value) = TYPE_WORD
			TYPE_OF(value) = TYPE_LIT_WORD
			TYPE_OF(value) = TYPE_GET_WORD
			TYPE_OF(value) = TYPE_SET_WORD
		]
		word: as red-word! value
		ctx: obj/ctx
		id: _context/find-word TO_CTX(ctx) word/symbol yes
		as red-value! either id = -1 [none-value][true-value]
	]
	
	select: func [
		obj		 [red-object!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
		/local
			word   [red-word!]
			ctx	   [red-context!]
			values [series!]
			node   [node!]
			id	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/select"]]
		
		assert any [									;@@ replace with ANY_WORD?
			TYPE_OF(value) = TYPE_WORD
			TYPE_OF(value) = TYPE_LIT_WORD
			TYPE_OF(value) = TYPE_GET_WORD
			TYPE_OF(value) = TYPE_SET_WORD
		]
		word: as red-word! value
		node: obj/ctx
		ctx: TO_CTX(node)
		id: _context/find-word ctx word/symbol yes
		if id = -1 [return as red-value! none-value]
		
		values: as series! ctx/values/value
		values/offset + id
	]
	
	init: does [
		datatype/register [
			TYPE_OBJECT
			TYPE_VALUE
			"object!"
			;-- General actions --
			:make
			null			;random
			:reflect
			null			;to
			:form
			:mold
			:eval-path
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
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			:copy
			:find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;next
			null			;pick
			null			;poke
			null			;remove
			null			;reverse
			:select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
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