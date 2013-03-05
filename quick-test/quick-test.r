REBOL [
  Title:   "Simple testing framework for Red and Red/System programs"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.r
	Version: 0.9.5
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %../red-system/utils/r2-forward.r

comment {
  This script makes some assumptions about the directory structure in which 
  files are stored. They are:
    this script is stored in Red/quick-test/
    the Red compiler is stored in Red/
    the Red/System compiler is stored in Red/red-system/
    the Red/System compiler must be run from Red/red-system/
    the Red/System compiler writes the executable to Red/red-system/builds/
    the default dir for Red/System tests is Red/red-system/tests/
    the default dir for Red tests is Red/red/tests/
    
 The default test dirs can be overriden by setting qt/rs-tests-dir and qt/r-tests-dir 
 before any tests are processed
}

qt: make object! [
  
  ;;;;;;;;;;; Setup ;;;;;;;;;;;;;;
  ;; set the base-dir to ....Red/
  base-dir: system/script/path 
  base-dir: copy/part base-dir find base-dir "quick-test"
  ;; set the red/system compiler directory
  comp-dir: base-dir/red-system
  ;; set the red/system runnable dir
  runnable-dir: comp-dir/tests/runnable
  ;; set the builds dir
  builds-dir: comp-dir/builds
  ;; set the default base dir for tests
  tests-dir: comp-dir/tests
  
  ;; set the red dirs
  r-runnable-dir: base-dir/red/tests/runnable
  r-tests-dir: base-dir/red/tests
  
  ;; set the version number
  version: system/script/header/version
  
  ;; set temporary files names
  ;;  use Red/red-system/runnable for Red/System temp files
  comp-echo: runnable-dir/comp-echo.txt
  comp-r: runnable-dir/comp.r
  test-src-file: runnable-dir/qt-test-comp.reds
  
  ;; use Red/red/runnable for Red temp files
  r-comp-echo: r-runnable-dir/comp-echo.txt
  r-comp-r: r-runnable-dir/comp.r
  r-test-src-file: r-runnable-dir/qt-test-comp.red
  
  ;; set log file 
  log-file: join system/script/path "quick-test.log"

  ;; make runnable directory if needed
  make-dir runnable-dir
  make-dir r-runnable-dir
  
  ;; windows ?
  windows-os?: system/version/4 = 3
  
  ;; use Cheyenne call with REBOL v2.7.8 on Windows (re: 'call bug on Windows 7)
  if all [
    windows-os?
    system/version/3 = 8              
  ][
		do %call.r					               
		set 'call :win-call
	]
  ;;;;;;;;;;; End Setup ;;;;;;;;;;;;;;
  
  comp-output: copy {}                 ;; output captured from compile
  output: copy #{}                     ;; output captured from pgm exec
  exe: none                            ;; filepath to executable
  reds-file?: true                     ;; true = running reds test file
                                       ;; false = runnning test script
  
  summary-template: ".. - .................................... / "
  
  data: make object! [
    title: copy ""
    no-tests: 0
    no-asserts: 0
    passes: 0
    failures: 0
    reset: does [
      title: copy ""
      no-tests: 0
      no-asserts: 0
      passes: 0
      failures: 0
    ]
  ]
  
  file: make data []
  test-run: make data []
  _add-file-to-run-totals: does [
    test-run/no-tests: test-run/no-tests + file/no-tests
    test-run/no-asserts: test-run/no-asserts + file/no-asserts
    test-run/passes: test-run/passes + file/passes
    test-run/failures: test-run/failures + file/failures
  ]
  _signify-failure: does [
    ;; called when a compiler or runtime error occurs
    file/failures: file/failures + 1           
    file/no-tests: file/no-tests + 1
    file/no-asserts: file/no-asserts + 1
    test-run/failures: test-run/failures + 1           
    test-run/no-tests: test-run/no-tests + 1
    test-run/no-asserts: test-run/no-asserts + 1
  ]
  
  ;; group data
  group-name: copy ""
  group?: false
  group-name-not-printed: true
  _init-group: does [
    group?: false
    group-name-not-printed: true
    group-name: copy ""
  ]
  
  ;; test data
  test-name: copy ""
  _init-test: does [
    test-name: copy ""
  ]
  
  ;; print diversion function
  _save-print: :print
  print-output: copy ""
  _quiet-print: func [val] [
    append print-output join "" [reduce val "^/"]
  ]
        
  compile: func [
    src [file!]
    /local
      comp                          ;; compilation script
      cmd                           ;; compilation cmd
      built                         ;; full path of compiler output
  ][
    clear comp-output
    ;; workout executable name
    if not exe: copy find/last/tail src "/" [exe: copy src]
    exe: copy/part exe find exe "."
    if windows-os? [
      exe: join exe [".exe"]
    ]

    ;; compose and write compilation script
    comp: mold compose [
      REBOL []
      halt: :quit
      change-dir (comp-dir)
      echo (comp-echo)
      do/args %rsc.r "***src***"
    ]
    if #"/" <> first src [src: tests-dir/:src]     ;; relative path supplied
    replace comp "***src***" src
    write comp-r comp

    ;; compose command line and call it
    cmd: join to-local-file system/options/boot [" -sc " comp-r]
    either r3? [
        ;; call in r3 is incomplete
        call/wait rejoin [cmd " > /dev/null"]
    ] [
        call/wait/output cmd make string! 1024	;; redirect output to anonymous buffer
    ]
    
    ;; collect compiler output & tidy up
    if exists? comp-echo [
    	comp-output: read-binary comp-echo
    	delete comp-echo
    ]
    if exists? comp-r [delete comp-r]
    
    ;; move the executable from /builds to /tests/runnable
    built: builds-dir/:exe
    runner: runnable-dir/:exe
    
    if exists? built [
      write-binary runner read-binary built
      delete built
      if not r3? [
		  if not windows-os? [
			r: open runner
			set-modes r [
			  owner-execute: true
			  group-execute: true
			]
			close r
		  ]
		] [
			make-owner-executable to-local-file runner
		]
    ]
    
    either compile-ok? [
      exe
    ][
      none
    ]    
  ]
  
  compile-and-run: func [src /error] [
    reds-file?: true
    either exe: compile src [
      either error [
        run/error  exe
      ][
        run exe
      ]
    ][
      compile-error src
      output: to binary! "Compilation failed"
    ]
  ]
    
  compile-and-run-from-string: func [src [string! binary!] /error] [
    reds-file?: false
    either exe: compile-from-string src [
      either error [
        run/error  exe
      ][
        run exe
      ]
    ][
      
      compile-error "Supplied source"
      output: to binary! "Compilation failed"
    ]
  ]
    
  compile-from-string: func [src [string! binary!]][
  	if string? src [
		src: to binary! r2-utf8-checked src
	]
  	
    ;-- add a default header if not provided
    if none = find src to binary! "Red/System" [
    	insert src to binary! "Red/System []^/"
    ]
    write test-src-file src
    compile test-src-file                  ;; returns path to executable or none
  ]
  
  compile-error: func [
    src [file! string!]
  ][
    print join "" [src " - compiler error"]
    print to string! comp-output
    clear output                           ;; clear the ouptut from previous test
    _signify-failure
  ]
  
  compile-ok?: func [] [
    either find comp-output to binary! "output file size:" [true] [false]
  ] 
  
  compile-run-print: func [src [file!] /error][
    either error [
      compile-and-run/error
    ][
      compile-and-run src
    ]
    if output <> to binary! "Compilation failed" [print to string! output]
  ]
  
  compiled?: func [
    src [string!]
  ][
    exe: compile-from-string src
    clean-compile-from-string
    qt/compile-ok?
  ]
  
  run: func [
    prog [file!]
    ;;/args                         ;; not yet needed
      ;;parms [string!]             ;; not yet needed
    /error                          ;; run time error expected
    /local
    exec [string!]                  ;; command to be executed
  ][
    exec: to-local-file runnable-dir/:prog
    ;;exec: join "" compose/deep [(exec either args [join " " parms] [""])]
    clear output
    either r3? [
    	;; was having strange thing where this wasn't executable, doublecheck
    	;; necessity later prior to checkin
    	make-owner-executable to file! exec
    	
        ;; call in R3 is incomplete
        tempfile: %qut-call-r3.tmp
        call/wait rejoin [exec " > " to string! tempfile]
        append output read-binary tempfile
    ] [
    	use [outstring] [
    		outstring: {}
        	call/output/wait exec outstring
        	
        	;-- R2 strings don't technically have unicode codepoints, they are
        	;-- just binary blocks passing the information through...
        	append output as-binary outstring
        ]
    ]
    if all [
      reds-file?
      none <> find output to binary! "Runtime Error" 
    ][
      if not error [_signify-failure]
    ]
  ]
  
  run-unit-test: func [
    src [file!]
    /local               
      cmd                             ;; command to run
      test-name                     
  ][
    reds-file?: false
    cmd: join to-local-file system/options/boot [" -sc " tests-dir src]
    call/wait cmd
  ]
  
  run-unit-test-quiet: func [
    src [file!]
    /local               
      cmd                             ;; command to run
      test-name                     
  ][
    reds-file?: false
    test-name: find/last/tail src "/"
    test-name: copy/part test-name find test-name "."
    prin [ "running " test-name #"^(0D)"]
    clear output
    cmd: join to-local-file system/options/boot [" -sc " tests-dir src]
    either r3? [
        ;; call in R3 is incomplete
        tempfile: %qut-call-r3.tmp
        call/wait rejoin [cmd " > " to string! tempfile]
        append output read-binary tempfile
    ] [ 
    	use [outstring] [
    		outstring: {}
        	call/output/wait cmd outstring
        	
       		;-- R2 strings don't technically have unicode codepoints, they are
        	;-- just binary blocks passing the information through...
        	append output as-binary outstring
 		]
    ]
    add-to-run-totals
    write/append log-file output
    file/title: test-name
    replace file/title "-test" ""
    _print-summary file
  ]
  
  run-script: func [
    src [file!]
    /local 
     filename                     ;; filename of script 
     script                       ;; %runnable/filename
  ][
    if not filename: copy find/last/tail src "/" [filename: copy src]
    script: runnable-dir/:filename
    write to file! script read-string join tests-dir [src]
    do script
  ]
  
  run-script-quiet: func [src [file!]][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    run-script src
    add-to-run-totals
    print: :_save-print
    write/append log-file print-output
    _print-summary file
  ]
  
  run-test-file: func [src [file!]][
    file/reset
    file/title: find/last/tail to string! src "/"
    replace file/title "-test.reds" ""
    compile-run-print src
    add-to-run-totals
  ]
  
  run-test-file-quiet: func [src [file!]][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    run-test-file src
    print: :_save-print
    write/append log-file print-output
    _print-summary file
    output: copy #{}
  ]
  
  r-compile: func [
    src [file!]
    /local
      comp                          ;; compilation script
      cmd                           ;; compilation cmd
      built                         ;; full path of compiler output
  ][
    clear comp-output
    ;; workout executable name
    either find src "/" [
      exe: copy find/last/tail src "/"
    ][
      exe: copy src
    ] 
    exe: copy/part exe find exe "."
    if windows-os? [
      exe: join exe [".exe"]
    ]
    runner: r-runnable-dir/:exe

    ;; compose and write compilation script
    comp: mold compose [
      REBOL []
      halt: :quit
      change-dir (base-dir)
      echo (r-comp-echo)
      do/args %red.r (join "-o " [runner " ***src***"])
    ]
    if #"/" <> first src [src: clean-path r-tests-dir/:src]     ;; relative path supplied
    replace comp "***src***" src
    write r-comp-r comp

    ;; compose command line and call it
    cmd: join to-local-file system/options/boot [" -sc " r-comp-r]
    either r3? [
        ;; call in r3 is incomplete
        call/wait rejoin [cmd " > /dev/null"]
    ] [
        call/wait/output cmd make string! 1024	;; redirect output to anonymous buffer
    ]
    
    ;; collect compiler output & tidy up
    if exists? r-comp-echo [
    	comp-output: read-binary r-comp-echo
    	delete r-comp-echo
    ]
    if exists? r-comp-r [delete r-comp-r]
    
    
    either r-compile-ok? [
      exe
    ][
      none
    ]    
  ]
  
  r-compile-ok?: func [] [
    either find comp-output to binary! "output file size:" [true] [false]
  ]
  
  r-compile-and-run: func [src /error] [
    either exe: r-compile src [
      either error [
        r-run/error  exe
      ][
        r-run exe
      ]
    ][
      compile-error src
      output: to binary! "Compilation failed"
    ]
  ]
  
  r-compile-run-print: func [src [file!] /error][
    either error [
      r-compile-and-run/error
    ][
      r-compile-and-run src
    ]
    if output <> to binary! "Compilation failed" [print output]
  ]
  
  r-compile-and-run-from-string: func [src [binary! string!] /error] [
    either exe: r-compile-from-string src [
      either error [
        r-run/error  exe
      ][
        r-run exe
      ]
    ][
      
      compile-error "Supplied source"
      output: to binary! "Compilation failed"
    ]
  ]
  
  r-compile-from-string: func [src [binary! string!]][
  	if string? src [
		src: to binary! r2-utf8-checked src
	]

    ;-- add a default header if not provided
    if none = find src to binary! "Red [" [insert src to binary! "Red []^/"]
    write r-test-src-file src
    r-compile r-test-src-file                  ;; returns path to executable or none
  ]
  
  r-run: func [
    prog [file!]
    ;;/args                         ;; not yet needed
      ;;parms [string!]             ;; not yet needed 
    /error                          ;; runtime error expected
    /local
    exec [string!]                   ;; command to be executed
  ][
    exec: to-local-file r-runnable-dir/:prog
    ;;exec: join "" compose/deep [(exec either args [join " " parms] [""])]
    clear output
    either r3? [
        ;; call in R3 is incomplete
        tempfile: %qut-call-r3.tmp
        call/wait rejoin [exec " > " to string! tempfile]
        append output read-binary tempfile
	] [
	    use [outstring] [
    		outstring: {}
        	call/output/wait exec outstring
        	
        	;-- R2 strings don't technically have unicode codepoints, they are
        	;-- just binary blocks passing the information through...
        	append output as-binary outstring
        ]
	]
    if windows-os? [output: qt/utf-16le-to-utf-8 output]
    if none <> find output to binary! "Script Error" [
      if not error [_signify-failure]
    ]
  ]
  
  r-run-test-file: func [src [file!]][
    file/reset
    file/title: find/last/tail to string! src "/"
    replace file/title "-test.red" ""
    r-compile-run-print src
    add-to-run-totals
  ]
  
  r-run-test-file-quiet: func [src [file!]][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    r-run-test-file src
    print: :_save-print
    write/append log-file print-output
    _print-summary file
    output: copy #{}
  ]
  
  add-to-run-totals: func [
    /local
      tests
      
      asserts
      passes
      failures
      rule
      digit
      number
  ][
    digit: charset [#"0" - #"9"]
    number: [some digit]
    ws: charset [#"^-" #"^/" #" "]
    whitespace: [some ws]
    rule: [
      thru "Number of Tests Performed:" whitespace copy tests number
      thru "Number of Assertions Performed:" whitespace copy asserts number
      thru "Number of Assertions Passed:" whitespace copy passed number
      thru "Number of Assertions Failed:" whitespace copy failures number
      to end
    ]
    if parse/all to string! output rule [
      file/no-tests: file/no-tests + to integer! tests
      file/no-asserts: file/no-asserts + to integer! asserts
      file/passes: file/passes + to integer! passed
      file/failures: file/failures + to integer! failures
      _add-file-to-run-totals
    ]
  ]
  
  _start: func [
    data [object!]
    leader [string!]
    title [string!]
  ][
    print [leader title]
    data/title: title
    data/no-tests: 0
    data/no-asserts: 0
    data/passes: 0
    data/failures: 0
    _init-group
  ]

  start-test-run: func [
    title [string!]
  ][
    _start test-run "***Starting***" title
    prin newline
  ]
  
  start-test-run-quiet: func [
    title [string!]
      ][
    _start test-run "" title
    prin newline
    write log-file rejoin ["***Starting***" title newline]
  ]
  
  start-file: func [
    title [string!]
  ][
    _start file "~~~started test~~~" title
  ]
  
  start-group: func[
    title [string!]
  ][
   group-name: title
   group?: true
  ]
  
  start-test: func[
    title [string!]
  ][
    _init-test
    test-name: title
    file/no-tests: file/no-tests + 1
  ]
    
  assert: func [
    assertion [logic!]
  ][
    file/no-asserts: file/no-asserts + 1
    either assertion [
      file/passes: file/passes + 1
    ][
      file/failures: file/failures + 1
      if group? [
        if group-name-not-printed [
          print ""
          print ["===group===" group-name]
        ]
      ]
      print ["---test---" test-name "FAILED**************"]
    ]
  ]
  
  assert-msg?: func [msg [string! binary!]][
    if string? msg [
    	msg: to binary! r2-utf8-checked msg
    ]
    assert found? find qt/comp-output msg
  ]
  
  assert-printed?: func [msg [string!]] [
    assert found? find qt/output msg
  ]
  
  assert-red-printed?: func [
    msg [string! binary!]
  ][
    if string? msg [
    	msg: to binary! r2-utf8-checked msg
    ]
    assert found? find output msg
  ]
      
  
  clean-compile-from-string: does [
    if exists? test-src-file [delete test-src-file]
    if all [exe exists? exe][delete exe]
]
  
  end-group: does [
    _init-group
  ]
  
  _end: func [
    data [object!]
    leader [string!]
  ][
    print [leader data/title]
    print ["No of tests  " data/no-tests]
    print ["No of asserts" data/no-asserts]
    print ["Passed       " data/passes]
    print ["Failed       " data/failures]
    if data/failures > 0 [print "***TEST FAILURES***"]
    print ""
  ]
  
  end-file: func [] [
    _end file "~~~finished test~~~" 
    _add-file-to-run-totals
  ]
  
  end-test-run: func [] [
      print ""
    _end test-run "***Finished***"
  ]
  
  end-test-run-quiet: func [] [
    print: :_quiet-print
    print-output: copy ""
    end-test-run
    print: :_save-print
    write/append log-file print-output
    prin newline
    _print-summary test-run
  ]
  
  _print-summary: func [
    data [object!]
    /local
      print-line
  ][
    print-line: copy summary-template
    print-line: skip print-line 5
    remove/part print-line length? data/title
    insert print-line data/title
    print-line: skip tail print-line negate (3 + length? mold data/passes)
    remove/part print-line length? mold data/passes
    insert print-line data/passes
    append print-line data/no-asserts
    print-line: head print-line
    either data/no-asserts = data/passes [
      replace print-line ".." "ok"
    ][
      replace/all print-line "." "*"
      append print-line " **"
    ]
    print print-line
  ]
  
  make-if-needed?: func [
    {This function is used by the Red run-all scripts to build the auto files
     when necessary. It is not } 
    auto-test-file [file!]
    make-file [file!]
    /lib-test
    /local
      stored-length   ; the length of the make... .r file used to build auto tests
      stored-file-length
      digit
      number
      rule
  ][
    auto-test-file: join tests-dir auto-test-file
    make-file: join tests-dir make-file
    
    stored-file-length: does [
      parse/all read-string auto-test-file rule
      stored-length
    ]
    digit: charset [#"0" - #"9"]
    number: [some digit]
    rule: [
      thru ";make-length:" 
      copy stored-length number (stored-length: to integer! stored-length)
      to end
    ]
    
    if not exists? make-file [return none]
   
    if any [
      not exists? auto-test-file
      stored-file-length <> length? read-string make-file
      (modified? make-file) > (modified? auto-test-file)
    ][
      print ["Making" auto-test-file " - it will take a while"]
      do make-file
    ]
  ]
  
  utf-16le-to-utf-8: func [
    {Translates a utf-16LE encoded binary to an utf-8 encoded one
     the algorithm is copied from lexer.r                         }
    in-str [binary!]
    /local
      out-str
      code
  ][
   out-str: copy #{}
   foreach [low high] in-str [
     code: high * 256 + low
     case [
       code <= 127  [
         append out-str to char! code					            ;-- c <= 7Fh
       ]
       code <= 2047 [							                        ;-- c <= 07FFh
         append out-str join "" [ 
           to char! ((shift code 6) and #"^(1F)" or #"^(C0)")
					 to char! ((code and #"^(3F)") or #"^(80)")
				 ]
			 ]
			 code <= 65535 [					                         		;-- c <= FFFFh
			   append out-str join "" [
			     to char! ((shift code 12) and #"^(0F)" or #"^(E0)")
			     to char! ((shift code 6) and #"^(3F)" or #"^(80)")
			     to char! (code and #"^(3F)" or #"^(80)")
			   ]
			 ]
			 code <= 1114111 [						                        ;-- c <= 10FFFFh
			   append out-str join "" [
			     to char! ((shift code 18) & ^"(07)" or #"^(F0)")
					 to char! ((shift code 12) and #"^(3F)" or #"^(80)")
					 to char! ((shift code 6)  and #"^(3F)" or #"^(80)")
					 to char! (code and #"^(3F)" or #"^(80)")
				 ]
			 ]                         ;-- Codepoints above U+10FFFF are ignored"
		 ]
	 ]
   out-str 
  ]
  
  ;; create the test "dialect"
  
  set '***start-run***              :start-test-run
  set '***start-run-quiet***        :start-test-run-quiet
  set '~~~start-file~~~             :start-file
  set '===start-group===            :start-group
  set '--test--                     :start-test
  set '--compile                    :compile
  set '--compile-red                :r-compile
  set '--compile-this               :compile-from-string
  set '--compile-this-red           :r-compile-from-string
  set '--compile-and-run            :compile-and-run
  set '--compile-and-run-red        :r-compile-and-run 
  set '--compile-and-run-this       :compile-and-run-from-string
  set '--compile-and-run-this-red   :r-compile-and-run-from-string
  set '--compile-run-print          :compile-run-print
  set '--compile-run-print-red      :r-compile-run-print
  set '--compiled?                  :compiled?
  set '--run                        :run
  set '--add-to-run-totals          :add-to-run-totals
  set '--run-unit-test              :run-unit-test
  set '--run-unit-test-quiet        :run-unit-test-quiet
  set '--run-script                 :run-script
  set '--run-script-quiet           :run-script-quiet
  set '--run-test-file              :run-test-file
  set '--run-test-file-red          :r-run-test-file
  set '--run-test-file-quiet        :run-test-file-quiet
  set '--run-test-file-quiet-red    :r-run-test-file-quiet
  set '--assert                     :assert
  set '--assert-msg?                :assert-msg?
  set '--assert-printed?            :assert-printed?
  set '--assert-red-printed?        :assert-red-printed?
  set '--clean                      :clean-compile-from-string
  set '===end-group===              :end-group
  set '~~~end-file~~~               :end-file
  set '***end-run***                :end-test-run
  set '***end-run-quiet***          :end-test-run-quiet
]
