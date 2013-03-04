Rebol [
	Title:   "Red lexer test script"
	Author:  "Peter W A Wood"
	File: 	 %byte-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; setup
store-halt: :halt
halt: func [][]

store-quiet-mode: system/options/quiet
system/options/quiet: false

do %../../../../quick-test/quick-unit-test.r
do %../../../lexer.r


~~~start-file~~~ "lexer"

===start-group=== "process"

	--test-- "lexer-1"
	src: {Red [] 123}
	--assert [[] 123] = lexer/process src
	
	--test-- "lexer-2"
	src: {Red [] aa}
	--assert [[] aa] = lexer/process src
	
	--test-- "lexer-3"
	src: {Red [] 'a}
	--assert [[] 'a] = lexer/process src
	
	--test-- "lexer-4"
	src: {Red [] a:}
	--assert [[] a:] = lexer/process src

	--test-- "lexer-5"
	src: {Red [] :a}
	--assert [[] :a] = lexer/process src

	--test-- "lexer-6"
	src: {Red [] /}
	--assert [[] /] = lexer/process src

	--test-- "lexer-7"
	src: {Red [] /test}
	--assert [[] /test] = lexer/process src

	--test-- "lexer-8"
	src: {Red [] (a)}
	--assert [[] (a)] = lexer/process src

	--test-- "lexer-9"
	src: {Red [] []}
	--assert [[] []] = lexer/process src

	--test-- "lexer-10"
	src: {Red [] "t"}
	--assert [[] "t"] = lexer/process src

	--test-- "lexer-11"
	src: {Red [] #"a"}
	--assert [[] #'00000061] = lexer/process src

	--test-- "lexer-12"
	src: {Red [] #a}
	--assert [[] #a] = lexer/process src

	--test-- "lexer-13"
	src: {Red [] #"^^(00)"}
	--assert [[] #'00000000] = lexer/process src

	--test-- "lexer-14"
	src: {Red [] foo/bar}
	--assert [[] foo/bar] = lexer/process src

	--test-- "lexer-15"
	src: {Red [] 'foo/bar}
	--assert [[] 'foo/bar] = lexer/process src

	--test-- "lexer-16"
	src: {Red [] foo/bar:}
	--assert [[] foo/bar:] = lexer/process src
	
	--test-- "lexer-17"
	;-- This originally tried to test a UTF-8 code that is too high for Rebol 3
	;-- as internally it cannot represent more than UCS-16.  But the Rebol 2
	;-- allowance of source-level Unicode is deceptive... it works only
	;-- because binaries could be aliased as string constants, and does not
	;-- represent any kind of systemic support for Unicode in the interpreter.
	;-- The proper full-spectrum Unicode tests of Red need to be in a UTF-8
	;-- formatted file fed to the compiler, not whiteboxed as either R2 or R3
	;-- code.  The codepoint tested was ^^(024B62).
	src: {
		Red [title: "test"]

		+ - 
		test123
		4 ttt 5655 /4545
		/ // -123 +5
		print /a 'lit-word
		b: (r + 4) test /refinement
		4545 "foo bar" ;-- comment

		#issue
		#{1234}

		#{
		45788956 ;-- test binary comment
		AAFFEEFF
		}

		comment {test

		}
		%foo/bar.red "foo^@^^/bar"

		{
	
	test
	^^(45)
	^^(A2)
	^^(00A2)
	^^(20AC)
	}

		either a = b [
			print [ok]
		][
			print [now]
		]

		foo/bar 'foo/bar foo/bar:
		#[none] #[true ] #[false ] 
	}
	
	result: compose [
		[title: "test"]
		+ -
		test123
		4 ttt 5655 /4545
		/ // -123 5
		print /a 'lit-word
		b: (quote (r + 4)) test /refinement
		4545 "foo bar"
		#issue
		#{1234}
		#{45788956AAFFEEFF}
		%foo/bar.red "foo^@^/bar"
		(to string! rejoin [to binary! {
^-
^-test
^-E
^-} #{C2A2} to binary! {
^-} #{C2A2} to binary! {
^-} #{E282AC} to binary! {
^-} ] )
		either a = b [
			print [ok]
		] [
			print [now]
		]
		foo/bar 'foo/bar foo/bar:
		#[none] #[true] #[false]
	]
	--assert result = processed: lexer/process src

	--test-- "lexer-20"
	  src: {
	    Red[]
	    a: 1
	  }
	--assert [[] a: 1] = lexer/process src

	--test-- "lexer-21"
	  src: {
	    Red[]
	    1: 1
	  }
	  lexer/process src
	--assert-printed? "*** Syntax Error: Invalid word! value"
	--assert-printed? "*** line: 2"
;	--assert-printed? {*** at: "1: 1} ;-- differing R3 output
	  
	--test-- "lexer-22"
	  src: {
	    Red/System[]
	    a: 1
	  }
	  lexer/process src
	--assert-printed? "*** Syntax Error: Invalid Red program"
	--assert-printed? "*** line: 1"
;	--assert-printed?  "*** at: {/System[]" ;-- differing R3 output
	
	--test-- "lexer-23"
	  src: {Red [] #"^^/"}
	--assert "[[] #'0000000A]" = mold lexer/process src
	  
===end-group===
	
~~~end-file~~~

;; tidy up
halt: :store-halt
system/options/quiet: :store-quiet-mode
prin ""

;;; #"a" #"^^/"

