Red/System [
	Title:   "Red runtime utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#either OS = 'Windows [
	get-cmdline-args: func [
		return: [red-value!]
		/local
			args [byte-ptr!]
	][
		args: platform/GetCommandLine
		as red-value! string/load as-c-string args platform/lstrlen args UTF-16LE
	]
][
	get-cmdline-args: func [
		return: [red-value!]
		/local
			str	 [red-string!]
			args [str-array!]
			new	 [c-string!]
			dst	 [c-string!]
			tail [c-string!]
			s	 [c-string!]
			size [integer!]
	][
		size: 10'000									;-- enough?
		new: as-c-string allocate size
		args: system/args-list 
		dst: new
		tail: new + size - 2							;-- leaving space for a terminal null

		until [
			s: args/item

			dst/1: #"^""
			dst: dst + 1
			until [
				dst/1: s/1
				dst: dst + 1
				s: s + 1
				any [s/1 = null-byte dst = tail]
			]
			dst/1: #"^""
			dst/2: #" "
			dst: dst + 2
			args: args + 1 
			any [args/item = null dst >= tail]
		]
		dst: dst - 1
		dst/1: null-byte
		str: string/load new length? new UTF-8
		free as byte-ptr! new
		as red-value! str
	]
]

check-arg-type: func [
	arg		[red-value!]
	type	[integer!]
][
	if TYPE_OF(arg) <> type [
		fire [TO_ERROR(script invalid-arg) arg]
	]
]