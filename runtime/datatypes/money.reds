Red/System [
	Title:   "Money! datatype runtime functions"
	Author:  "Vladimir Vasilyev"
	File: 	 %money.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

money: context [
	verbose: 0
	
	;-- Base --
	
	#enum sizes! [
		SIZE_BYTES: 11								;-- total number of bytes used to store amount
		SIZE_SCALE: 05								;-- total number of digits (nibbles) used to store scale (fractional part)
		SIZE_AFTER: 05								;-- how many digits to print after a decimal separator
	]
	
	SIZE_DIGITS:   SIZE_BYTES * 2					;-- total number of digits (nibbles) used to store amount
	SIZE_INTEGRAL: SIZE_DIGITS - SIZE_SCALE			;-- size of an integral part (digits)
	
	SIZE_UNNORM: SIZE_DIGITS + SIZE_SCALE					;-- size of unnormalized result (digits)
	SIZE_BUFFER: (SIZE_UNNORM + (SIZE_UNNORM and 1)) >> 1	;-- size of memory portion that stores unnormalized result (bytes)
	
	SIZE_SBYTES: (SIZE_BUFFER + size? integer!) - (SIZE_BUFFER // size? integer!)
	SIZE_SSLOTS: SIZE_SBYTES >> 2					;-- total number of bytes / stack slots allocated to hold unnormalized result
	
	HIGH_NIBBLE: #"^(0F)"
	LOW_NIBBLE:  #"^(F0)"
	
	SIGN_MASK:   4000h								;-- used to get/set sign bit in the header
	SIGN_OFFSET: 14
	
	MAX_FRACTIONAL: as integer! (pow 10.0 as float! SIZE_SCALE) - 1.0
	INT32_MAX_DIGITS: 10
	INT32_MIN_AMOUNT: #{00000002147483648FFFFF}		;-- 0xF > 0x9, used to subvert comparison
	INT32_MAX_AMOUNT: #{00000002147483647FFFFF}
	
	#enum signs! [
	;--    sign	 -0+
	;--	integer	-101
	;-- 	 +1	 012
	
		SIGN_--: 00h
		SIGN_-0: 01h
		SIGN_-+: 02h
		
		SIGN_0-: 10h
		SIGN_00: 11h
		SIGN_0+: 12h
		
		SIGN_+-: 20h
		SIGN_+0: 21h
		SIGN_++: 22h
	]
	
	#enum make-states! [
		S_START
		S_CURRENCY
		S_INTEGRAL
		S_FRACTIONAL
		S_END
	]
	
	#define DISPATCH_SIGNS [switch collate-signs this-sign that-sign]
	#define SWAP_ARGUMENTS(this that) [use [hold][hold: this this: that that: hold]]
	
	#define MONEY_OVERFLOW [fire [TO_ERROR(script type-limit) datatype/push TYPE_MONEY]]
	
	;-- Sign --
	
	get-sign: func [
		money   [red-money!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/get-sign"]]
		money/header and SIGN_MASK >> SIGN_OFFSET
	]
	
	set-sign: func [
		money   [red-money!]
		sign    [integer!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/set-sign"]]
		
		money/header: money/header and (not SIGN_MASK) or (sign << SIGN_OFFSET)
		money
	]
	
	flip-sign: func [
		money   [red-money!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/flip-sign"]]
		set-sign money as integer! not as logic! get-sign money
	]
	
	collate-signs: func [
		this    [integer!]
		that    [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/collate-signs"]]
		this + 1 << 4 or (that + 1)
	]
	
	;-- Amount --
	
	get-amount: func [
		money   [red-money!]
		return: [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/get-amount"]]
		(as byte-ptr! money) + (size? money) - SIZE_BYTES
	]
	
	zero-amount?: func [
		amount  [byte-ptr!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/zero-amount?"]]
		
		loop SIZE_BYTES [
			unless null-byte = amount/value [return no]
			amount: amount + 1
		]
		
		yes
	]
	
	compare-amounts: func [
		this    [byte-ptr!]
		that    [byte-ptr!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/compare-amounts"]]
		compare-memory this that SIZE_BYTES
	]
	
	zero-out: func [
		money   [red-money!]
		all?    [logic!]							;-- no: keep currency index
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/zero-out"]]
		
		money/amount1: either all? [0][money/amount1 and FF000000h]
		money/amount2: 0
		money/amount3: 0
		
		money
	]
	
	shift-left: func [
		amount  [byte-ptr!]
		size    [integer!]
		offset  [integer!]
		return: [byte-ptr!]
		/local
			this that [integer!]
			half      [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/shift-left"]]
		
		loop offset [
			this: 1
			that: this + 1
			loop size [
				half: either that > size [null-byte][amount/that >>> 4]
				amount/this: amount/this << 4 or half
				
				this: this + 1
				that: that + 1
			]
		]
		
		amount
	]
	
	shift-right: func [
		amount  [byte-ptr!]
		size    [integer!]
		offset  [integer!]
		return: [byte-ptr!]
		/local
			this that [integer!]
			half      [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/shift-right"]]
		
		loop offset [
			this: size
			that: this - 1
			loop size [
				half: either that < 1 [null-byte][amount/that << 4]
				amount/this: amount/this >>> 4 or half
				
				this: this - 1
				that: that - 1
			]
		]
		
		amount
	]
	
	;-- Digits --
	
	get-digit: func [
		amount  [byte-ptr!]
		index   [integer!]
		return: [integer!]
		/local
			bit byte offset [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/get-digit"]]
		
		assert positive? index
		
		bit:    index and 1
		byte:   index >> 1 + bit
		offset: either as logic! bit [4][0]
		
		as integer! amount/byte and (HIGH_NIBBLE << offset) >>> offset
	]
	
	set-digit: func [
		amount [byte-ptr!]
		index  [integer!]
		value  [integer!]
		/local
			bit byte offset reverse [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/set-digit"]]

		assert positive? index
		assert all [value >= 0 value <= 9]
	
		bit:     index and 1
		byte:    index >> 1 + bit
		offset:  either as logic! bit [4][0]
		reverse: either zero? offset  [4][0]
		
		amount/byte: amount/byte and (HIGH_NIBBLE << reverse) or as byte! (value << offset)
	]
	
	count-digits: func [
		amount  [byte-ptr!]
		return: [integer!]
		/local
			count [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/count-digits"]]
		
		count: SIZE_DIGITS
		loop SIZE_BYTES [
			either null-byte = amount/value [count: count - 2][
				count: count - as integer! null-byte = (amount/value and LOW_NIBBLE)
				break
			]
			amount: amount + 1
		]
		
		either zero? count [1][count]				;-- 0 is a single digit
	]
	
	;-- Slices --
	
	compare-slices: func [
		this-buffer [byte-ptr!] this-high? [logic!] this-count [integer!]
		that-buffer [byte-ptr!] that-high? [logic!] that-count [integer!]
		return: [integer!]
		/local
			delta index1 index2 end this that [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/compare-slices"]]
		
		delta: integer/abs this-count - that-count
		switch integer/sign? this-count - that-count [
			-1 [index1: 1 - delta index2: 1 end: that-count]
			00 [index1: 1         index2: 1 end: this-count]
			+1 [index2: 1 - delta index1: 1 end: this-count]
			default [0]
		]
		
		index1: index1 + as integer! this-high?
		index2: index2 + as integer! that-high?
		
		until [
			this: either index1 < 1 [0][get-digit this-buffer index1]
			that: either index2 < 1 [0][get-digit that-buffer index2]
		
			index1: index1 + 1
			index2: index2 + 1
			end:    end - 1
			
			any [this <> that zero? end]
		]
		
		this - that
	]
	
	subtract-slice: func [
		this-buffer [byte-ptr!] this-high? [logic!] this-count [integer!]
		that-buffer [byte-ptr!] that-high? [logic!] that-count [integer!]
		/local
			this that borrow difference [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/subtract-slice"]]
		
		this-count: this-count + as integer! this-high?
		that-count: that-count + as integer! that-high?
		borrow: 0
		until [
			this: get-digit this-buffer this-count
			that: either that-count < 1 [0][get-digit that-buffer that-count]
			
			difference: this - that - borrow		;-- assumming this >= that
			borrow: as integer! difference < 0
			if as logic! borrow [difference: difference + 10]
			
			set-digit this-buffer this-count difference
			
			this-count: this-count - 1
			that-count: that-count - 1
			
			zero? this-count
		]
	]
	
	;-- Construction --
	
	make-at: func [
		slot     [red-value!]
		sign     [logic!]
		currency [byte-ptr!]
		start    [byte-ptr!]
		point    [byte-ptr!]
		end      [byte-ptr!]
		return:  [red-money!]
		/local
			convert     [subroutine!]
			money       [red-money!]
			here amount [byte-ptr!]
			limit       [byte-ptr!]
			index stop  [integer!]
			step        [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make-at"]]
		
		money: as red-money! slot
		money/header: TYPE_MONEY
		
		zero-out money yes
		set-sign money as integer! sign
		;@@ TBD: store currency index
		amount: get-amount money
		
		convert: [
			here: here + step
			until [
				if here/value = #"'" [here: here + step continue]	;-- skip thousands separators
				set-digit amount index as integer! here/value - #"0"
				
				here:  here + step
				index: index + step
				any [index = stop here = limit]
			]
		]
		
		;-- integral part
		here:  either null? point [end][point]
		limit: start
		index: SIZE_INTEGRAL
		stop:  0
		step:  -1
		
		convert
		
		if null? point [return money]
		
		;-- fractional part
		here:  point
		limit: end
		index: SIZE_INTEGRAL + 1
		stop:  SIZE_DIGITS + 1
		step:  +1
		
		convert
		
		money
	]
	
	make-in: func [
		parent   [red-block!]
		sign     [logic!]
		currency [byte-ptr!]
		start    [byte-ptr!]
		point    [byte-ptr!]
		end      [byte-ptr!]
		return:  [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make-in"]]
		make-at ALLOC_TAIL(parent) sign currency start point end
	]
	
	push: func [
		sign     [logic!]
		currency [byte-ptr!]
		start    [byte-ptr!]
		point    [byte-ptr!]
		end      [byte-ptr!]
		return:  [red-money!]	
	][
		#if debug? = yes [if verbose > 0 [print-line "money/push"]]
		make-at stack/push* sign currency start point end
	]
	
	form-money: func [
		money   [red-money!]
		buffer  [red-string!]
		part    [integer!]
		group?  [logic!]
		return: [integer!]
		/local
			fill        [subroutine!]
			amount      [byte-ptr!]
			sign count  [integer!]
			index times [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/form-money"]]
		
		amount: get-amount money
		sign:   sign? money
		
		if negative? sign [
			string/concatenate-literal buffer "-"
			part: part - 1
		]
		
		;@@ TBD: take currency into account
		
		string/concatenate-literal buffer "$"
		
		count: count-digits amount
		index: SIZE_DIGITS - count + 1
		
		fill: [
			loop times [
				string/concatenate-literal
					buffer
					integer/form-signed get-digit amount index
				
				if all [group? zero? (index + 1 // 3) index <> SIZE_INTEGRAL][
					string/concatenate-literal buffer "'"
					part: part - 1
				]
				
				index: index + 1
				part:  part - 1
			]		
		]
		
		times: count - SIZE_SCALE
		either positive? times [fill][
			string/concatenate-literal buffer "0"
			index: SIZE_INTEGRAL + 1
			part:  part - 1
		]
		
		string/concatenate-literal buffer "."
		
		group?: no
		times:  SIZE_AFTER
		fill
		
		part - 2									;-- compensate for $ and . characters
	]
	
	;-- Conversion --
	
	overflow?: func [
		money   [red-money!]
		return: [logic!]
		/local
			amount limit [byte-ptr!]
			sign count   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/overflow?"]]
		
		sign: sign? money
		if zero? sign [return no]
		
		amount: get-amount money
		count:  (count-digits amount) - SIZE_SCALE
		if count <> INT32_MAX_DIGITS [return count > INT32_MAX_DIGITS]
		
		limit: either negative? sign [INT32_MIN_AMOUNT][INT32_MAX_AMOUNT]	;-- worst case: need to compare amount with constant buffers (equal size)
		positive? compare-amounts amount limit
	]
	
	to-integer: func [
		money   [red-money!]
		return: [integer!]
		/local
			amount             [byte-ptr!]
			sign integer index [integer!]
			start power digit  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/to-integer"]]
		
		if overflow? money [fire [TO_ERROR(script type-limit) datatype/push TYPE_INTEGER]]
	
		sign: sign? money
		if zero? sign [return 0]
	
		amount:  get-amount money
		integer: 0
		index:   SIZE_INTEGRAL
		start:   index
		
		loop INT32_MAX_DIGITS [
			digit:   get-digit amount index
			power:   as integer! pow 10.0 as float! start - index
			integer: integer + (digit * power)
			
			index: index - 1
		]
		
		sign * integer
	]
	
	from-integer: func [
		int     [integer!]
		return: [red-money!]
		/local
			money             [red-money!]
			amount            [byte-ptr!]
			extra index start [integer!]
			power digit       [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/from-integer"]]
		
		money: zero-out as red-money! stack/push* yes
		money/header: TYPE_MONEY
		
		if zero? int [return money]
		
		set-sign money as integer! negative? int
		
		extra: as integer! int = (1 << 31)			;-- if it's an integer minimum, prevent math overflow
		int:   integer/abs int + extra
		
		amount: get-amount money
		index:  SIZE_INTEGRAL
		start:  index
		
		loop INT32_MAX_DIGITS [
			power: as integer! pow 10.0 as float! start - index
			digit: int / power // 10
			
			unless zero? digit [set-digit amount index digit]
			
			index: index - 1
		]
		
		unless zero? extra [						;-- compensate for overflow prevention
			set-digit amount start extra + get-digit amount start
		]
		
		money
	]
	
	to-float: func [
		money   [red-money!]
		return: [float!]
		/local
			buffer       [red-string!]
			head         [byte-ptr!]
			float        [float!]
			sign delta   [integer!]
			length error [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/to-float"]]
		
		sign: sign? money
		
		if zero? sign [return 0.0]
	
		buffer: string/make-at stack/push* SIZE_DIGITS + 6 Latin1	;-- max number of digits and -CCC$.
		form-money money buffer 0 no
		
		delta:  (string/rs-find buffer as integer! #"$") + 1
		head:   (string/rs-head buffer) + delta
		length: (string/rs-length? buffer) - delta
		
		error: 0
		float: string/to-float head length :error
		stack/pop 1
		
		unless zero? error [
			fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_FLOAT money]
		]
		
		float * as float! sign
	]
	
	from-float: func [
		flt     [float!]
		return: [red-money!]
		/local
			money     [red-money!]
			formed    [c-string!]
			start end [byte-ptr!]
			point     [byte-ptr!]
			sign      [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/from-float"]]
		
		formed: dtoa/form-float flt SIZE_DIGITS yes
		
		point: as byte-ptr! formed
		until [point: point + 1 point/value = #"."]
		
		if point/2 = #"#" [							;-- 1.#NaN, 1.#INF
			fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY float/box flt]
		]
		
		sign:  formed/1 = #"-"
		start: as byte-ptr! either sign [formed][formed - 1]
		end:   as byte-ptr! formed + length? formed
		
		money: push sign null start point end
		if all [0.0 <> flt zero? sign? money][MONEY_OVERFLOW]	;-- underflow on too small float value
		money
	]
	
	to-binary: func [
		money   [red-money!]
		return: [red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/to-binary"]]
		binary/load-in get-amount money SIZE_BYTES null
	]
	
	from-binary: func [
		bin     [red-binary!]
		return: [red-money!]
		/local
			money  [red-money!]
			head   [byte-ptr!]
			length [integer!]
			index  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/from-binary"]]
		
		length: binary/rs-length? bin
		if length > SIZE_BYTES [length: SIZE_BYTES]	;-- take only first SIZE_BYTES bytes into account
		
		head: binary/rs-head bin
		index: 1
		loop length << 1 [
			if 9 < get-digit head index [
				fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY bin]
			]
			index: index + 1
		]
		
		money: zero-out as red-money! stack/push* yes
		money/header: TYPE_MONEY
		
		copy-memory (get-amount money) + SIZE_BYTES - length head length
		money
	]
		
	from-block: func [
		blk     [red-block!]
		return: [red-money!]
		/local
			bail              [subroutine!]
			money fraction    [red-money!]
			int               [red-integer!]
			flt               [red-float!]
			head tail here    [red-value!]
			state type length [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/from-block"]]
		
		bail: [fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY blk]]
		
		length: block/rs-length? blk
		if any [length < 1 length > 3][bail]
		
		head: block/rs-head blk
		tail: block/rs-tail blk
		here: head
		
		state: S_START
		while [state <> S_END][
			type: TYPE_OF(here)
			switch state [
				S_START [
					switch type [
						TYPE_WORD [state: S_CURRENCY]
						TYPE_INTEGER
						TYPE_FLOAT [state: S_INTEGRAL]
						default [bail]
					]
				]
				S_CURRENCY [
					;@@ TBD: take currency into account
					here: here + 1
					if here = tail [bail]
					state: S_INTEGRAL
				]
				S_INTEGRAL [
					switch type [
						TYPE_INTEGER [
							int: as red-integer! here
							money: from-integer int/value
						]
						TYPE_FLOAT [
							flt: as red-float! here
							money: from-float flt/value
						]
						default [bail]
					]
					here: here + 1
					state: either here = tail [S_END][S_FRACTIONAL]
				]
				S_FRACTIONAL [
					either type <> TYPE_INTEGER [bail][
						int: as red-integer! here
						if any [negative? int/value int/value > MAX_FRACTIONAL][bail]
						
						fraction: set-sign from-integer int/value get-sign money
						shift-right get-amount fraction SIZE_BYTES SIZE_SCALE
						money: add-money money fraction
						
						here: here + 1
						if here <> tail [bail]
						state: S_END
					]
				]
			]
		]
		
		money
	]
	
	from-string: func [
		str     [red-string!]
		return: [red-money!]
		/local
			bail make       [subroutine!]
			end? dot?       [subroutine!]
			digit? letter?  [subroutine!]
			tail head here  [byte-ptr!]
			currency digits [byte-ptr!]
			start point     [byte-ptr!]
			char            [byte!]
			sign            [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/from-string"]]
		
		bail: [fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY str]]
		make: [return push sign currency start point tail]
		
		end?:    [here >= tail]
		dot?:    [any [here/value  = #"." here/value  = #","]]
		digit?:  [all [here/value >= #"0" here/value <= #"9"]]
		letter?: [
			any [
				all [here/value >= #"a" here/value <= #"z"]
				all [here/value >= #"A" here/value <= #"Z"]
			]
		]
		
		tail: string/rs-tail str
		head: string/rs-head str
		here: head
		
		;-- sign
		sign: no
		switch here/value [
			#"-" [here: here + 1 sign: yes]
			#"+" [here: here + 1]
			default [0]
		]
		
		;-- currency code
		currency: here
		while [not any [end? here/value = #"$"]][here: here + 1]
		
		if end? [here: currency]
		either here = currency [currency: null][
			if currency + 3 <> here [bail]
			loop 3 [here: here - 1 unless letter? [bail]]
			here: here + 3
		]
		
		start: here - as integer! here/value <> #"$"
		here:  start + 1
		
		;-- leading zeroes
		until [here: here + 1 any [here = tail here/value <> #"0"]]
		if any [here = tail dot?][here: here - 1]
		digits: here
		
		;-- integral part with optional thousands separators
		until [
			if here/value = #"'" [here: here + 1 continue]
			unless digit? [bail]								;-- forbid leading decimal separator
			here: here + 1
			any [end? dot?]
		]
		
		if any [here > tail all [dot? here + 1 = tail]][bail]	;-- forbid trailing decimal separator
		
		point: here
		if SIZE_INTEGRAL < as integer! point - digits [bail]
		if here = tail [point: null make]
		here: here + 1
		
		;-- fractional part
		until [unless digit? [bail] here: here + 1 end?]
		if here <> tail [bail]
		
		make
	]
	
	;-- Comparison --
	
	compare-money: func [
		this    [red-money!]
		that    [red-money!]
		return: [integer!]
		/local
			this-sign that-sign [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/compare-money"]]
		
		;@@ TBD: take currencies into account
	
		this-sign: sign? this
		that-sign: sign? that
		
		DISPATCH_SIGNS [
			SIGN_-- [SWAP_ARGUMENTS(this that) 0]
			SIGN_++ [0]
			default [return integer/sign? this-sign - that-sign]
		]
		
		integer/sign? compare-amounts get-amount this get-amount that	;-- must return strictly -1, 0 or +1
	]
	
	negative-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/negative-money?"]]
		negative? sign? money
	]
	
	zero-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/zero-money?"]]
		zero? sign? money
	]
	
	positive-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/positive-money?"]]
		positive? sign? money
	]
	
	sign?: func [
		money   [red-money!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/sign?"]]
		
		either zero-amount? get-amount money [0][
			either as logic! get-sign money [-1][+1]
		]
	]
	
	;-- Math --
	
	absolute-money: func [
		money   [red-money!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/absolute-money"]]
		set-sign money 0							;-- 0: clear sign bit
	]
	
	negate-money: func [
		money   [red-money!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/negate-money"]]
		flip-sign money
	]
	
	add-money: func [								;-- long addition
		augend  [red-money!]
		addend  [red-money!]
		return: [red-money!]
		/local
			this-amount that-amount    [byte-ptr!]
			this-sign that-sign        [integer!]
			index carry left right sum [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/add-money"]]
		
		this-sign: sign? augend
		that-sign: sign? addend
		
		DISPATCH_SIGNS [
			SIGN_00
			SIGN_-0
			SIGN_+0 [return augend]
			SIGN_0-
			SIGN_0+ [return addend]		
			SIGN_+- [return subtract-money augend absolute-money addend]
			SIGN_-+ [return subtract-money addend absolute-money augend]
			default [0]
		]
		
		this-amount: get-amount augend
		that-amount: get-amount addend
		
		if (get-digit this-amount 1) + (get-digit that-amount 1) > 9 [MONEY_OVERFLOW]	;-- if sum of two most significant digits overflows
		
		index: SIZE_DIGITS
		carry: 0
		
		loop index [
			left:  get-digit this-amount index
			right: get-digit that-amount index
			
			sum:   left + right + carry
			carry: sum / 10
			unless zero? carry [sum: sum + 6 and 0Fh]
			
			set-digit this-amount index sum
		
			index: index - 1
		]
		
		if as logic! carry [MONEY_OVERFLOW]
		
		augend
	]
	
	subtract-money: func [							;-- long subtraction
		minuend    [red-money!]
		subtrahend [red-money!]
		return:    [red-money!]
		/local
			this-amount that-amount  [byte-ptr!]
			this-sign that-sign sign [integer!]
			index borrow left right  [integer!]
			difference               [integer!]
			lesser? flag             [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/subtract-money"]]
		
		this-sign: sign? minuend
		that-sign: sign? subtrahend
		
		DISPATCH_SIGNS [			
			SIGN_00
			SIGN_0-
			SIGN_0+ [return negate-money subtrahend]
			SIGN_-0
			SIGN_+0 [return minuend]
			SIGN_-+ [return negate-money add-money absolute-money minuend absolute-money subtrahend]
			SIGN_+- [return add-money minuend absolute-money subtrahend]
			default [
				lesser?: negative? compare-money minuend subtrahend
				sign: as integer! lesser?
				
				either positive? this-sign [flag: lesser?][
					minuend: absolute-money minuend
					subtrahend: absolute-money subtrahend
					flag: not lesser?
				]
				
				if flag [SWAP_ARGUMENTS(minuend subtrahend)]
			]
		]
		
		this-amount: get-amount minuend
		that-amount: get-amount subtrahend
		
		index:  SIZE_DIGITS
		borrow: 0
	
		loop index [
			left:  get-digit this-amount index
			right: get-digit that-amount index
			
			difference: left - right - borrow
			borrow: as integer! negative? difference
			if as logic! borrow [difference: difference + 10]
			
			set-digit this-amount index difference
		
			index: index - 1
		]
		
		set-sign minuend sign
	]
	
	multiply-money: func [							;-- long multiplication
		multiplicand [red-money!]
		multiplier   [red-money!]
		return:      [red-money!]
		/local
			this-amount that-amount product [byte-ptr!]
			this-sign that-sign sign        [integer!]
			this-count that-count           [integer!]
			delta index1 index2 index3      [integer!]
			carry left right other result   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/multiply-money"]]
		
		this-sign: sign? multiplicand
		that-sign: sign? multiplier
		
		DISPATCH_SIGNS [
			SIGN_00
			SIGN_0-
			SIGN_0+ [return multiplicand]
			SIGN_+0
			SIGN_-0 [return multiplier]
			default [sign: as integer! this-sign <> that-sign]
		]
		
		this-amount: get-amount multiplicand
		that-amount: get-amount multiplier
		
		this-count: count-digits this-amount
		that-count: count-digits that-amount
		
		if (this-count + that-count) > (SIZE_UNNORM + 1) [MONEY_OVERFLOW]	;-- if after normalization it won't fit into payload
		
		product: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
		
		delta:  SIZE_DIGITS - SIZE_BUFFER << 1
		index1: SIZE_DIGITS
		
		loop that-count [
			carry:  0
			index2: SIZE_DIGITS
			
			loop this-count [
				index3: index1 + index2 - delta
			
				left:  get-digit this-amount index2
				right: get-digit that-amount index1
				other: get-digit product     index3
				
				result: left * right + other + carry
				carry:  result /  10
				result: result // 10
				
				set-digit product index3 result
				
				index2: index2 - 1
			]
			
			set-digit product index3 - 1 carry
			
			index1: index1 - 1
		]
		
		unless zero? get-digit product 1 [MONEY_OVERFLOW]	;-- overflowed into most-significant digit
		
		shift-right product SIZE_SBYTES SIZE_SCALE
		product: product + SIZE_BUFFER - SIZE_BYTES
		
		if zero-amount? product [MONEY_OVERFLOW]			;-- got zero product from non-zero factors
		
		copy-memory this-amount product SIZE_BYTES
		set-sign multiplicand sign
	]
	
	divide-money: func [							;-- shift-and-subtract algorithm
		dividend   [red-money!]
		divisor    [red-money!]
		remainder? [logic!]							;-- yes: calculate remainder instead
		only?      [logic!]							;-- yes: don't approximate fractional part
		return:    [red-money!]
		/local
			shift increment subtract   [subroutine!]
			greater? greatest?         [subroutine!]
			this-amount that-amount    [byte-ptr!]
			this-start that-start      [byte-ptr!]
			quotient buffer hold       [byte-ptr!]
			this-sign that-sign sign   [integer!]
			this-count that-count      [integer!]
			size overflow digits index [integer!]
			this-high? that-high?      [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/divide-money"]]
		
		this-sign: sign? dividend
		that-sign: sign? divisor
		
		DISPATCH_SIGNS [
			SIGN_00
			SIGN_+0
			SIGN_-0 [fire [TO_ERROR(math zero-divide)]]
			SIGN_0-
			SIGN_0+ [return dividend]
			default [
				sign: as integer! either remainder? [negative? this-sign][this-sign <> that-sign]
			]
		]
		
		this-amount: get-amount dividend
		that-amount: get-amount divisor
		
		this-count: count-digits this-amount
		that-count: count-digits that-amount
		
		if this-count + (SIZE_SCALE + 1 - that-count) > SIZE_DIGITS [MONEY_OVERFLOW]	;-- if after normalization it won't fit into payload
		
		size: SIZE_DIGITS
		overflow: SIZE_SBYTES << 1 - SIZE_DIGITS
		
		unless any [remainder? only?][
			size: SIZE_SBYTES << 1
			hold: this-amount
			
			this-amount: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
			this-count:  this-count + SIZE_SCALE
			
			copy-memory this-amount + SIZE_SBYTES - SIZE_BYTES hold SIZE_BYTES
			shift-left this-amount SIZE_SBYTES SIZE_SCALE
		]
		
		this-high?: as logic! this-count and 1
		that-high?: as logic! that-count and 1
		
		this-start: this-amount + (size        - this-count >> 1)
		that-start: that-amount + (SIZE_DIGITS - that-count >> 1)
		
		digits: either this-count < that-count [this-count][that-count]
		
		index:    size - (integer/abs this-count - that-count) - SIZE_SCALE
		quotient: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
		buffer:   quotient
		
		if any [remainder? only?][quotient: quotient + SIZE_SBYTES - SIZE_BYTES]
		
		shift: [
			digits: digits + 1
			index:  index  + 1
		]
		subtract: [
			subtract-slice
				this-start this-high? digits
				that-start that-high? that-count
		]
		increment: [
			set-digit quotient index (get-digit quotient index) + 1
		]
		greater?: [
			compare-slices
				that-start that-high? that-count
				this-start this-high? digits
		]
		greatest?: [
			compare-slices
				that-start that-high? that-count
				this-start this-high? this-count
		]
		;@@ TBD: bug with subroutines
		until [either greater? > 0 [either greatest? > 0 [yes][shift no]][subtract increment no]]
		
		unless remainder? [
			unless only? [
				shift-right quotient SIZE_SBYTES SIZE_SCALE
				quotient: quotient + SIZE_SBYTES - SIZE_BYTES
				this-amount: hold
			]
			if zero-amount? quotient [MONEY_OVERFLOW]				;-- got zero quotient from non-zero dividend
			unless zero? get-digit buffer overflow [MONEY_OVERFLOW] ;-- overflowed into most-significant digit
			copy-memory this-amount quotient SIZE_BYTES
		]
		
		set-sign dividend sign
	]

	do-math-op: func [
		left    [red-money!]
		right   [red-money!]
		op      [integer!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/do-math-op"]]
		
		switch op [
			OP_ADD [add-money left right]
			OP_SUB [subtract-money left right]
			OP_MUL [multiply-money left right]
			OP_DIV [divide-money left right no no]
			OP_REM [divide-money left right yes no]
			default [
				fire [TO_ERROR (script invalid-type) datatype/push TYPE_OF(left)]
				left								;-- pass compiler's type checking
			]
		]
	]

	do-math: func [
		op      [integer!]
		return: [red-value!]
		/local
			left right [red-money!]
			result     [red-value!]
			int        [red-integer!]
			flt        [red-float!]
			left-type  [integer!]
			right-type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/do-math"]]
		
		left:  as red-money! stack/arguments
		right: left + 1
		
		left-type:  TYPE_OF(left)
		right-type: TYPE_OF(right)
	
		if any [
			all [op = OP_MUL left-type = TYPE_MONEY right-type = TYPE_MONEY]
			all [any [op = OP_DIV op = OP_REM] left-type <> TYPE_MONEY right-type = TYPE_MONEY]
		][
			fire [TO_ERROR(script invalid-type) datatype/push left-type]
		]
		
		;@@ TBD: take currencies into account
	
		switch left-type [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				int: as red-integer! left
				left:    from-integer int/value
			]
			TYPE_FLOAT [
				flt: as red-float! left
				left:  from-float flt/value
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(left)]
			]
		]
	
		switch right-type [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				int: as red-integer! right
				right:   from-integer int/value
			]
			TYPE_FLOAT [
				flt: as red-float! right
				right: from-float flt/value
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		
		result: as red-value! do-math-op left right op
		if all [op = OP_DIV left-type = TYPE_MONEY right-type = TYPE_MONEY][
			result: as red-value! float/box to-float as red-money! result
		]
		SET_RETURN(result)							;-- some of the operations swap their argument slots
	]
		
	;-- Actions --
	
	make: func [
		proto   [red-value!]
		spec    [red-value!]
		type    [integer!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make"]]
	
		switch TYPE_OF(spec) [
			TYPE_BLOCK  [from-block as red-block! spec]
			TYPE_BINARY [from-binary as red-binary! spec]
			default [to proto spec type]
		]
	]

	to: func [
		proto   [red-value!]
		spec    [red-value!]
		type    [integer!]
		return: [red-money!]
		/local
			integer [red-integer!]
			float   [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/to"]]
		
		switch TYPE_OF(spec) [
			TYPE_MONEY [
				return as red-money! spec
			]
			TYPE_INTEGER [
				integer: as red-integer! spec
				from-integer integer/value
			]
			TYPE_FLOAT [
				float: as red-float! spec
				from-float float/value
			]
			TYPE_ANY_STRING [
				from-string as red-string! spec
			]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MONEY spec]
				as red-money! proto					;-- pass compiler's type checking
			]
		]
	]
	
	random: func [
		money   [red-money!]
		seed?   [logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/random"]]
		--NOT_IMPLEMENTED--
		money
	]
	
	form: func [
		money   [red-money!]
		buffer  [red-string!]
		arg     [red-value!]
		part    [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/form"]]
		form-money money buffer part yes
	]
	
	mold: func [
		money   [red-money!]
		buffer  [red-string!]
		only?   [logic!]
		all?    [logic!]
		flat?   [logic!]
		arg     [red-value!]
		part    [integer!]
		indent  [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/mold"]]
		form-money money buffer part no
	]
		
	compare: func [
		money   [red-money!]
		value   [red-money!]
		op      [integer!]
		return: [integer!]
		/local
			integer [red-integer!]
			float   [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/compare"]]
		
		if all [
			TYPE_OF(money) <> TYPE_OF(value)
			any [op = COMP_FIND op = COMP_SAME op = COMP_STRICT_EQUAL]
		][
			return 1
		]
		
		;@@ TBD: take currencies into account (strict comparison)
		
		switch TYPE_OF(value) [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				integer: as red-integer! value
				value:   from-integer integer/value
			]
			TYPE_FLOAT [
				float: as red-float! value
				value: from-float float/value
			]
			default [RETURN_COMPARE_OTHER]
		]
		
		compare-money money value
	]
	
	absolute: func [return: [red-money!]][
		#if debug? = yes [if verbose > 0 [print-line "money/absolute"]]
		absolute-money as red-money! stack/arguments
	]
	
	negate: func [return: [red-money!]][
		#if debug? = yes [if verbose > 0 [print-line "money/negate"]]
		negate-money as red-money! stack/arguments
	]
	
	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/add"]]	
		do-math OP_ADD
	]
	
	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/subtract"]]
		do-math OP_SUB
	]
	
	multiply: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/multiply"]]
		do-math OP_MUL
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/divide"]]
		do-math OP_DIV
	]
	
	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/remainder"]]	
		do-math OP_REM
	]
	
	round: func [
		value      [red-money!]
		scale      [red-float!]
		_even?     [logic!]
		down?      [logic!]
		half-down? [logic!]
		floor?     [logic!]
		ceil?      [logic!]
		half-ceil? [logic!]
		return:    [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/round"]]
		--NOT_IMPLEMENTED--
		value
	]
	
	even?: func [
		money   [red-money!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/even?"]]
		not odd? money
	]
	
	odd?: func [
		money   [red-money!]
		return: [logic!]
		/local
			digit [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/odd?"]]
		
		digit: get-digit get-amount money SIZE_INTEGRAL	;-- check if least significant bit is set
		as logic! digit and 1
	]
	
	init: does [
		datatype/register [
			TYPE_MONEY
			TYPE_VALUE
			"money!"
			;-- General actions --
			:make
			:random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			:round
			:subtract
			:even?
			:odd?
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
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
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