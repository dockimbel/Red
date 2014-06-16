Red [
	Title:   "Red TO action test script"
	Author:  "Oldes"
	File: 	 to-action-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "to"

===start-group=== "to-char!"
        --test-- "to-char!-char!"
                --assert #"a" = to char! #"a"
        --test-- "to-char!-string!"
                --assert #"f" = to char! "foo"
        --test-- "to-char!-integer!"
                --assert #"{" = to char! 123
        --test-- "to-char!-integer!"
                --assert #"─Ç" = to char! 256
        --test-- "to-char!-decimal!"
                --assert #"^A" = to char! 1.5
        --test-- "to-char!-binary!"
                --assert #"a" = to char! #{616263}
===end-group===
===start-group=== "to-string!"
        --test-- "to-string!-char!"
                --assert "a" = to string! #"a"
        --test-- "to-string!-string!"
                --assert "foo" = to string! "foo"
        --test-- "to-string!-integer!"
                --assert "123" = to string! 123
        --test-- "to-string!-integer!"
                --assert "256" = to string! 256
        --test-- "to-string!-decimal!"
                --assert "1.5" = to string! 1.5
        --test-- "to-string!-integer!"
                --assert "-1" = to string! -1
        --test-- "to-string!-decimal!"
                --assert "-1.5" = to string! -1.5
        --test-- "to-string!-pair!"
                --assert "1x2" = to string! 1x2
        --test-- "to-string!-word!"
                --assert "word" = to string! word
        --test-- "to-string!-refinement!"
                --assert "/refinement" = to string! /refinement
        --test-- "to-string!-path!"
                --assert "path/foo" = to string! path/foo
        --test-- "to-string!-url!"
                --assert "http://red-lang.org" = to string! http://red-lang.org
        --test-- "to-string!-file!"
                --assert "/file/" = to string! %/file/
        --test-- "to-string!-issue!"
                --assert "#FF00" = to string! #FF00
        --test-- "to-string!-binary!"
                --assert "" = to string! #{}
        --test-- "to-string!-binary!"
                --assert "abc" = to string! #{616263}
        --test-- "to-string!-block!"
                --assert "" = to string! []
        --test-- "to-string!-block!"
                --assert "12" = to string! [1 2]
        --test-- "to-string!-block!"
                --assert "123" = to string! [1 2 3]
        --test-- "to-string!-block!"
                --assert "ab" = to string! ["a" "b"]
;       --test-- "to-string!-tuple!"
;               --assert "1.1.1" = to string! 1.1.1
        --test-- "to-string!-paren!"
                --assert "" = to string! ()
        --test-- "to-string!-paren!"
                --assert "12" = to string! (1 2)
;       --test-- "to-string!-tag!"
;               --assert "a" = to string! <a>
;       --test-- "to-string!-time!"
;               --assert "10:00" = to string! 10:00
;       --test-- "to-string!-date!"
;               --assert "16-Jun-2014/14:34:59+2:00" = to string! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-string!-email!"
;               --assert "foo@boo" = to string! foo@boo
        --test-- "to-string!-bitset!"
                --assert "make bitset! #{00}" = to string! make bitset! #{00}
===end-group===
===start-group=== "to-integer!"
        --test-- "to-integer!-char!"
                --assert 97 = to integer! #"a"
        --test-- "to-integer!-integer!"
                --assert 123 = to integer! 123
        --test-- "to-integer!-integer!"
                --assert 256 = to integer! 256
        --test-- "to-integer!-decimal!"
                --assert 1 = to integer! 1.5
        --test-- "to-integer!-integer!"
                --assert -1 = to integer! -1
        --test-- "to-integer!-decimal!"
                --assert -1 = to integer! -1.5
        --test-- "to-integer!-issue!"
                --assert 65280 = to integer! #FF00
        --test-- "to-integer!-binary!"
                --assert 0 = to integer! #{}
        --test-- "to-integer!-binary!"
                --assert 6382179 = to integer! #{616263}
;       --test-- "to-integer!-time!"
;               --assert 36000 = to integer! 10:00
===end-group===
===start-group=== "to-decimal!"
        --test-- "to-decimal!-char!"
                --assert 97.0 = to decimal! #"a"
        --test-- "to-decimal!-integer!"
                --assert 123.0 = to decimal! 123
        --test-- "to-decimal!-integer!"
                --assert 256.0 = to decimal! 256
        --test-- "to-decimal!-decimal!"
                --assert 1.5 = to decimal! 1.5
        --test-- "to-decimal!-integer!"
                --assert -1.0 = to decimal! -1
        --test-- "to-decimal!-decimal!"
                --assert -1.5 = to decimal! -1.5
        --test-- "to-decimal!-binary!"
                --assert 0.0 = to decimal! #{}
        --test-- "to-decimal!-binary!"
                --assert 3.1532154e-317 = to decimal! #{616263}
        --test-- "to-decimal!-block!"
                --assert 100.0 = to decimal! [1 2]
        --test-- "to-decimal!-paren!"
                --assert 100.0 = to decimal! (1 2)
;       --test-- "to-decimal!-time!"
;               --assert 36000.0 = to decimal! 10:00
===end-group===
===start-group=== "to-pair!"
        --test-- "to-pair!-integer!"
                --assert 123x123 = to pair! 123
        --test-- "to-pair!-integer!"
                --assert 256x256 = to pair! 256
        --test-- "to-pair!-decimal!"
                --assert 1.5x1.5 = to pair! 1.5
        --test-- "to-pair!-integer!"
                --assert -1x-1 = to pair! -1
        --test-- "to-pair!-decimal!"
                --assert -1.5x-1.5 = to pair! -1.5
        --test-- "to-pair!-pair!"
                --assert 1x2 = to pair! 1x2
        --test-- "to-pair!-block!"
                --assert 1x2 = to pair! [1 2]
===end-group===
===start-group=== "to-word!"
        --test-- "to-word!-char!"
                --assert a = to word! #"a"
        --test-- "to-word!-string!"
                --assert foo = to word! "foo"
        --test-- "to-word!-word!"
                --assert word = to word! word
        --test-- "to-word!-refinement!"
                --assert refinement = to word! /refinement
        --test-- "to-word!-issue!"
                --assert FF00 = to word! #FF00
===end-group===
===start-group=== "to-refinement!"
        --test-- "to-refinement!-char!"
                --assert /a = to refinement! #"a"
        --test-- "to-refinement!-string!"
                --assert /foo = to refinement! "foo"
        --test-- "to-refinement!-word!"
                --assert /word = to refinement! word
        --test-- "to-refinement!-refinement!"
                --assert /refinement = to refinement! /refinement
        --test-- "to-refinement!-issue!"
                --assert /FF00 = to refinement! #FF00
===end-group===
===start-group=== "to-path!"
        --test-- "to-path!-char!"
                --assert #"a" = to path! #"a"
        --test-- "to-path!-string!"
                --assert foo = to path! "foo"
        --test-- "to-path!-integer!"
                --assert 123 = to path! 123
        --test-- "to-path!-integer!"
                --assert 256 = to path! 256
        --test-- "to-path!-decimal!"
                --assert 1.5 = to path! 1.5
        --test-- "to-path!-integer!"
                --assert -1 = to path! -1
        --test-- "to-path!-decimal!"
                --assert -1.5 = to path! -1.5
        --test-- "to-path!-pair!"
                --assert 1x2 = to path! 1x2
        --test-- "to-path!-word!"
                --assert word = to path! word
        --test-- "to-path!-refinement!"
                --assert /refinement = to path! /refinement
        --test-- "to-path!-path!"
                --assert path/foo = to path! path/foo
        --test-- "to-path!-url!"
                --assert http://red-lang.org = to path! http://red-lang.org
        --test-- "to-path!-file!"
                --assert %/file/ = to path! %/file/
        --test-- "to-path!-issue!"
                --assert #FF00 = to path! #FF00
        --test-- "to-path!-binary!"
                --assert #[path! []] = to path! #{}
        --test-- "to-path!-binary!"
                --assert abc = to path! #{616263}
        --test-- "to-path!-block!"
                --assert #[path! []] = to path! []
        --test-- "to-path!-block!"
                --assert 1/2 = to path! [1 2]
        --test-- "to-path!-block!"
                --assert 1/2/3 = to path! [1 2 3]
        --test-- "to-path!-block!"
                --assert "a"/"b" = to path! ["a" "b"]
;       --test-- "to-path!-tuple!"
;               --assert 1.1.1 = to path! 1.1.1
        --test-- "to-path!-paren!"
                --assert #[path! []] = to path! ()
        --test-- "to-path!-paren!"
                --assert 1/2 = to path! (1 2)
;       --test-- "to-path!-tag!"
;               --assert <a> = to path! <a>
;       --test-- "to-path!-time!"
;               --assert 10:00 = to path! 10:00
;       --test-- "to-path!-date!"
;               --assert 16-Jun-2014/14:34:59+2:00 = to path! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-path!-email!"
;               --assert foo@boo = to path! foo@boo
        --test-- "to-path!-bitset!"
                --assert make bitset! #{00} = to path! make bitset! #{00}
===end-group===
===start-group=== "to-url!"
        --test-- "to-url!-char!"
                --assert a = to url! #"a"
        --test-- "to-url!-string!"
                --assert foo = to url! "foo"
        --test-- "to-url!-integer!"
                --assert 123 = to url! 123
        --test-- "to-url!-integer!"
                --assert 256 = to url! 256
        --test-- "to-url!-decimal!"
                --assert 1.5 = to url! 1.5
        --test-- "to-url!-integer!"
                --assert -1 = to url! -1
        --test-- "to-url!-decimal!"
                --assert -1.5 = to url! -1.5
        --test-- "to-url!-pair!"
                --assert 1x2 = to url! 1x2
        --test-- "to-url!-word!"
                --assert word = to url! word
        --test-- "to-url!-refinement!"
                --assert /refinement = to url! /refinement
        --test-- "to-url!-path!"
                --assert path/foo = to url! path/foo
        --test-- "to-url!-url!"
                --assert http://red-lang.org = to url! http://red-lang.org
        --test-- "to-url!-file!"
                --assert /file/ = to url! %/file/
        --test-- "to-url!-issue!"
                --assert #FF00 = to url! #FF00
        --test-- "to-url!-binary!"
                --assert  = to url! #{}
        --test-- "to-url!-binary!"
                --assert abc = to url! #{616263}
        --test-- "to-url!-block!"
                --assert  = to url! []
        --test-- "to-url!-block!"
                --assert 12 = to url! [1 2]
        --test-- "to-url!-block!"
                --assert 123 = to url! [1 2 3]
        --test-- "to-url!-block!"
                --assert ab = to url! ["a" "b"]
;       --test-- "to-url!-tuple!"
;               --assert 1.1.1 = to url! 1.1.1
        --test-- "to-url!-paren!"
                --assert  = to url! ()
        --test-- "to-url!-paren!"
                --assert 12 = to url! (1 2)
;       --test-- "to-url!-tag!"
;               --assert a = to url! <a>
;       --test-- "to-url!-time!"
;               --assert 10:00 = to url! 10:00
;       --test-- "to-url!-date!"
;               --assert 16-Jun-2014/14:34:59+2:00 = to url! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-url!-email!"
;               --assert foo@boo = to url! foo@boo
        --test-- "to-url!-bitset!"
                --assert make%20bitset!%20#%7B00%7D = to url! make bitset! #{00}
===end-group===
===start-group=== "to-file!"
        --test-- "to-file!-char!"
                --assert %a = to file! #"a"
        --test-- "to-file!-string!"
                --assert %foo = to file! "foo"
        --test-- "to-file!-integer!"
                --assert %123 = to file! 123
        --test-- "to-file!-integer!"
                --assert %256 = to file! 256
        --test-- "to-file!-decimal!"
                --assert %1.5 = to file! 1.5
        --test-- "to-file!-integer!"
                --assert %-1 = to file! -1
        --test-- "to-file!-decimal!"
                --assert %-1.5 = to file! -1.5
        --test-- "to-file!-pair!"
                --assert %1x2 = to file! 1x2
        --test-- "to-file!-word!"
                --assert %word = to file! word
        --test-- "to-file!-refinement!"
                --assert %/refinement = to file! /refinement
        --test-- "to-file!-path!"
                --assert %path/foo = to file! path/foo
        --test-- "to-file!-url!"
                --assert %http://red-lang.org = to file! http://red-lang.org
        --test-- "to-file!-file!"
                --assert %/file/ = to file! %/file/
        --test-- "to-file!-issue!"
                --assert %#FF00 = to file! #FF00
        --test-- "to-file!-binary!"
                --assert %"" = to file! #{}
        --test-- "to-file!-binary!"
                --assert %abc = to file! #{616263}
        --test-- "to-file!-block!"
                --assert %"" = to file! []
        --test-- "to-file!-block!"
                --assert %12 = to file! [1 2]
        --test-- "to-file!-block!"
                --assert %123 = to file! [1 2 3]
        --test-- "to-file!-block!"
                --assert %ab = to file! ["a" "b"]
;       --test-- "to-file!-tuple!"
;               --assert %1.1.1 = to file! 1.1.1
        --test-- "to-file!-paren!"
                --assert %"" = to file! ()
        --test-- "to-file!-paren!"
                --assert %12 = to file! (1 2)
;       --test-- "to-file!-tag!"
;               --assert %a = to file! <a>
;       --test-- "to-file!-time!"
;               --assert %10:00 = to file! 10:00
;       --test-- "to-file!-date!"
;               --assert %16-Jun-2014/14:34:59+2:00 = to file! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-file!-email!"
;               --assert %foo@boo = to file! foo@boo
        --test-- "to-file!-bitset!"
                --assert %make%20bitset!%20#%7B00%7D = to file! make bitset! #{00}
===end-group===
===start-group=== "to-issue!"
        --test-- "to-issue!-char!"
                --assert #a = to issue! #"a"
        --test-- "to-issue!-string!"
                --assert #foo = to issue! "foo"
        --test-- "to-issue!-word!"
                --assert #word = to issue! word
        --test-- "to-issue!-refinement!"
                --assert #refinement = to issue! /refinement
        --test-- "to-issue!-issue!"
                --assert #FF00 = to issue! #FF00
===end-group===
===start-group=== "to-binary!"
        --test-- "to-binary!-char!"
                --assert #{61} = to binary! #"a"
        --test-- "to-binary!-string!"
                --assert #{666F6F} = to binary! "foo"
        --test-- "to-binary!-integer!"
                --assert #{000000000000007B} = to binary! 123
        --test-- "to-binary!-integer!"
                --assert #{0000000000000100} = to binary! 256
        --test-- "to-binary!-decimal!"
                --assert #{3FF8000000000000} = to binary! 1.5
        --test-- "to-binary!-integer!"
                --assert #{FFFFFFFFFFFFFFFF} = to binary! -1
        --test-- "to-binary!-decimal!"
                --assert #{BFF8000000000000} = to binary! -1.5
        --test-- "to-binary!-url!"
                --assert #{687474703A2F2F7265642D6C616E672E6F7267} = to binary! http://red-lang.org
        --test-- "to-binary!-file!"
                --assert #{2F66696C652F} = to binary! %/file/
        --test-- "to-binary!-binary!"
                --assert #{} = to binary! #{}
        --test-- "to-binary!-binary!"
                --assert #{616263} = to binary! #{616263}
        --test-- "to-binary!-block!"
                --assert #{} = to binary! []
        --test-- "to-binary!-block!"
                --assert #{0102} = to binary! [1 2]
        --test-- "to-binary!-block!"
                --assert #{010203} = to binary! [1 2 3]
        --test-- "to-binary!-block!"
                --assert #{6162} = to binary! ["a" "b"]
;       --test-- "to-binary!-tuple!"
;               --assert #{010101} = to binary! 1.1.1
;       --test-- "to-binary!-tag!"
;               --assert #{61} = to binary! <a>
;       --test-- "to-binary!-email!"
;               --assert #{666F6F40626F6F} = to binary! foo@boo
        --test-- "to-binary!-bitset!"
                --assert #{00} = to binary! make bitset! #{00}
===end-group===
===start-group=== "to-block!"
        --test-- "to-block!-char!"
                --assert [ #"a"] = to block! #"a"
        --test-- "to-block!-string!"
                --assert [foo] = to block! "foo"
        --test-- "to-block!-integer!"
                --assert [ 123] = to block! 123
        --test-- "to-block!-integer!"
                --assert [ 256] = to block! 256
        --test-- "to-block!-decimal!"
                --assert [ 1.5] = to block! 1.5
        --test-- "to-block!-integer!"
                --assert [ -1] = to block! -1
        --test-- "to-block!-decimal!"
                --assert [ -1.5] = to block! -1.5
        --test-- "to-block!-pair!"
                --assert [ 1x2] = to block! 1x2
        --test-- "to-block!-word!"
                --assert [ word] = to block! word
        --test-- "to-block!-refinement!"
                --assert [ /refinement] = to block! /refinement
        --test-- "to-block!-path!"
                --assert [path foo] = to block! path/foo
        --test-- "to-block!-url!"
                --assert [ http://red-lang.org] = to block! http://red-lang.org
        --test-- "to-block!-file!"
                --assert [ %/file/] = to block! %/file/
        --test-- "to-block!-issue!"
                --assert [ #FF00] = to block! #FF00
        --test-- "to-block!-binary!"
                --assert [] = to block! #{}
        --test-- "to-block!-binary!"
                --assert [abc] = to block! #{616263}
        --test-- "to-block!-block!"
                --assert [] = to block! []
        --test-- "to-block!-block!"
                --assert [1 2] = to block! [1 2]
        --test-- "to-block!-block!"
                --assert [1 2 3] = to block! [1 2 3]
        --test-- "to-block!-block!"
                --assert ["a" "b"] = to block! ["a" "b"]
;       --test-- "to-block!-tuple!"
;               --assert [ 1.1.1] = to block! 1.1.1
        --test-- "to-block!-paren!"
                --assert [] = to block! ()
        --test-- "to-block!-paren!"
                --assert [1 2] = to block! (1 2)
;       --test-- "to-block!-tag!"
;               --assert [ <a>] = to block! <a>
;       --test-- "to-block!-time!"
;               --assert [ 10:00] = to block! 10:00
;       --test-- "to-block!-date!"
;               --assert [ 16-Jun-2014/14:34:59+2:00] = to block! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-block!-email!"
;               --assert [ foo@boo] = to block! foo@boo
        --test-- "to-block!-bitset!"
                --assert [make bitset! #{00}] = to block! make bitset! #{00}
===end-group===
===start-group=== "to-tuple!"
;       --test-- "to-tuple!-issue!"
;               --assert 255.0.0 = to tuple! #FF00
;       --test-- "to-tuple!-binary!"
;               --assert 0.0.0 = to tuple! #{}
;       --test-- "to-tuple!-binary!"
;               --assert 97.98.99 = to tuple! #{616263}
;       --test-- "to-tuple!-block!"
;               --assert 0.0.0 = to tuple! []
;       --test-- "to-tuple!-block!"
;               --assert 1.2.0 = to tuple! [1 2]
;       --test-- "to-tuple!-block!"
;               --assert 1.2.3 = to tuple! [1 2 3]
;       --test-- "to-tuple!-tuple!"
;               --assert 1.1.1 = to tuple! 1.1.1
;       --test-- "to-tuple!-paren!"
;               --assert 0.0.0 = to tuple! ()
;       --test-- "to-tuple!-paren!"
;               --assert 1.2.0 = to tuple! (1 2)
===end-group===
===start-group=== "to-paren!"
        --test-- "to-paren!-char!"
                --assert ( #"a") = to paren! #"a"
        --test-- "to-paren!-string!"
                --assert (foo) = to paren! "foo"
        --test-- "to-paren!-integer!"
                --assert ( 123) = to paren! 123
        --test-- "to-paren!-integer!"
                --assert ( 256) = to paren! 256
        --test-- "to-paren!-decimal!"
                --assert ( 1.5) = to paren! 1.5
        --test-- "to-paren!-integer!"
                --assert ( -1) = to paren! -1
        --test-- "to-paren!-decimal!"
                --assert ( -1.5) = to paren! -1.5
        --test-- "to-paren!-pair!"
                --assert ( 1x2) = to paren! 1x2
        --test-- "to-paren!-word!"
                --assert ( word) = to paren! word
        --test-- "to-paren!-refinement!"
                --assert ( /refinement) = to paren! /refinement
        --test-- "to-paren!-path!"
                --assert (path foo) = to paren! path/foo
        --test-- "to-paren!-url!"
                --assert ( http://red-lang.org) = to paren! http://red-lang.org
        --test-- "to-paren!-file!"
                --assert ( %/file/) = to paren! %/file/
        --test-- "to-paren!-issue!"
                --assert ( #FF00) = to paren! #FF00
        --test-- "to-paren!-binary!"
                --assert () = to paren! #{}
        --test-- "to-paren!-binary!"
                --assert (abc) = to paren! #{616263}
        --test-- "to-paren!-block!"
                --assert () = to paren! []
        --test-- "to-paren!-block!"
                --assert (1 2) = to paren! [1 2]
        --test-- "to-paren!-block!"
                --assert (1 2 3) = to paren! [1 2 3]
        --test-- "to-paren!-block!"
                --assert ("a" "b") = to paren! ["a" "b"]
;       --test-- "to-paren!-tuple!"
;               --assert ( 1.1.1) = to paren! 1.1.1
        --test-- "to-paren!-paren!"
                --assert () = to paren! ()
        --test-- "to-paren!-paren!"
                --assert (1 2) = to paren! (1 2)
;       --test-- "to-paren!-tag!"
;               --assert ( <a>) = to paren! <a>
;       --test-- "to-paren!-time!"
;               --assert ( 10:00) = to paren! 10:00
;       --test-- "to-paren!-date!"
;               --assert ( 16-Jun-2014/14:34:59+2:00) = to paren! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-paren!-email!"
;               --assert ( foo@boo) = to paren! foo@boo
        --test-- "to-paren!-bitset!"
                --assert (make bitset! #{00}) = to paren! make bitset! #{00}
===end-group===
===start-group=== "to-tag!"
;       --test-- "to-tag!-char!"
;               --assert <a> = to tag! #"a"
;       --test-- "to-tag!-string!"
;               --assert <foo> = to tag! "foo"
;       --test-- "to-tag!-integer!"
;               --assert <123> = to tag! 123
;       --test-- "to-tag!-integer!"
;               --assert <256> = to tag! 256
;       --test-- "to-tag!-decimal!"
;               --assert <1.5> = to tag! 1.5
;       --test-- "to-tag!-integer!"
;               --assert <-1> = to tag! -1
;       --test-- "to-tag!-decimal!"
;               --assert <-1.5> = to tag! -1.5
;       --test-- "to-tag!-pair!"
;               --assert <1x2> = to tag! 1x2
;       --test-- "to-tag!-word!"
;               --assert <word> = to tag! word
;       --test-- "to-tag!-refinement!"
;               --assert </refinement> = to tag! /refinement
;       --test-- "to-tag!-path!"
;               --assert <path/foo> = to tag! path/foo
;       --test-- "to-tag!-url!"
;               --assert <http://red-lang.org> = to tag! http://red-lang.org
;       --test-- "to-tag!-file!"
;               --assert </file/> = to tag! %/file/
;       --test-- "to-tag!-issue!"
;               --assert <#FF00> = to tag! #FF00
;       --test-- "to-tag!-binary!"
;               --assert <> = to tag! #{}
;       --test-- "to-tag!-binary!"
;               --assert <abc> = to tag! #{616263}
;       --test-- "to-tag!-block!"
;               --assert <> = to tag! []
;       --test-- "to-tag!-block!"
;               --assert <12> = to tag! [1 2]
;       --test-- "to-tag!-block!"
;               --assert <123> = to tag! [1 2 3]
;       --test-- "to-tag!-block!"
;               --assert <ab> = to tag! ["a" "b"]
;       --test-- "to-tag!-tuple!"
;               --assert <1.1.1> = to tag! 1.1.1
;       --test-- "to-tag!-paren!"
;               --assert <> = to tag! ()
;       --test-- "to-tag!-paren!"
;               --assert <12> = to tag! (1 2)
;       --test-- "to-tag!-tag!"
;               --assert <a> = to tag! <a>
;       --test-- "to-tag!-time!"
;               --assert <10:00> = to tag! 10:00
;       --test-- "to-tag!-date!"
;               --assert <16-Jun-2014/14:34:59+2:00> = to tag! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-tag!-email!"
;               --assert <foo@boo> = to tag! foo@boo
;       --test-- "to-tag!-bitset!"
;               --assert <make bitset! #{00}> = to tag! make bitset! #{00}
===end-group===
===start-group=== "to-time!"
;       --test-- "to-time!-integer!"
;               --assert 0:02:03 = to time! 123
;       --test-- "to-time!-integer!"
;               --assert 0:04:16 = to time! 256
;       --test-- "to-time!-decimal!"
;               --assert 0:00:01.5 = to time! 1.5
;       --test-- "to-time!-integer!"
;               --assert -0:00:01 = to time! -1
;       --test-- "to-time!-decimal!"
;               --assert -0:00:01.499999999 = to time! -1.5
;       --test-- "to-time!-block!"
;               --assert 1:02 = to time! [1 2]
;       --test-- "to-time!-block!"
;               --assert 1:02:03 = to time! [1 2 3]
;       --test-- "to-time!-paren!"
;               --assert 1:02 = to time! (1 2)
;       --test-- "to-time!-time!"
;               --assert 10:00 = to time! 10:00
===end-group===
===start-group=== "to-date!"
;       --test-- "to-date!-block!"
;               --assert 1-Feb-0003 = to date! [1 2 3]
;       --test-- "to-date!-date!"
;               --assert 16-Jun-2014/14:34:59+2:00 = to date! 16-Jun-2014/14:34:59+2:00
===end-group===
===start-group=== "to-email!"
;       --test-- "to-email!-char!"
;               --assert a = to email! #"a"
;       --test-- "to-email!-string!"
;               --assert foo = to email! "foo"
;       --test-- "to-email!-integer!"
;               --assert 123 = to email! 123
;       --test-- "to-email!-integer!"
;               --assert 256 = to email! 256
;       --test-- "to-email!-decimal!"
;               --assert 1.5 = to email! 1.5
;       --test-- "to-email!-integer!"
;               --assert -1 = to email! -1
;       --test-- "to-email!-decimal!"
;               --assert -1.5 = to email! -1.5
;       --test-- "to-email!-pair!"
;               --assert 1x2 = to email! 1x2
;       --test-- "to-email!-word!"
;               --assert word = to email! word
;       --test-- "to-email!-refinement!"
;               --assert /refinement = to email! /refinement
;       --test-- "to-email!-path!"
;               --assert path/foo = to email! path/foo
;       --test-- "to-email!-url!"
;               --assert http://red-lang.org = to email! http://red-lang.org
;       --test-- "to-email!-file!"
;               --assert /file/ = to email! %/file/
;       --test-- "to-email!-issue!"
;               --assert #FF00 = to email! #FF00
;       --test-- "to-email!-binary!"
;               --assert  = to email! #{}
;       --test-- "to-email!-binary!"
;               --assert abc = to email! #{616263}
;       --test-- "to-email!-block!"
;               --assert  = to email! []
;       --test-- "to-email!-block!"
;               --assert 12 = to email! [1 2]
;       --test-- "to-email!-block!"
;               --assert 123 = to email! [1 2 3]
;       --test-- "to-email!-block!"
;               --assert ab = to email! ["a" "b"]
;       --test-- "to-email!-tuple!"
;               --assert 1.1.1 = to email! 1.1.1
;       --test-- "to-email!-paren!"
;               --assert  = to email! ()
;       --test-- "to-email!-paren!"
;               --assert 12 = to email! (1 2)
;       --test-- "to-email!-tag!"
;               --assert a = to email! <a>
;       --test-- "to-email!-time!"
;               --assert 10:00 = to email! 10:00
;       --test-- "to-email!-date!"
;               --assert 16-Jun-2014/14:34:59+2:00 = to email! 16-Jun-2014/14:34:59+2:00
;       --test-- "to-email!-email!"
;               --assert foo@boo = to email! foo@boo
;       --test-- "to-email!-bitset!"
;               --assert make%20bitset!%20#%7B00%7D = to email! make bitset! #{00}
===end-group===
===start-group=== "to-bitset!"
        --test-- "to-bitset!-char!"
                --assert make bitset! #{00000000000000000000000040} = to bitset! #"a"
        --test-- "to-bitset!-string!"
                --assert make bitset! #{0000000000000000000000000201} = to bitset! "foo"
        --test-- "to-bitset!-integer!"
                --assert make bitset! #{00000000000000000000000000000000} = to bitset! 123
        --test-- "to-bitset!-integer!"
                --assert make bitset! #{0000000000000000000000000000000000000000000000000000000000000000} = to bitset! 256
        --test-- "to-bitset!-url!"
                --assert make bitset! #{0000000000070020000000004D8BA8} = to bitset! http://red-lang.org
        --test-- "to-bitset!-file!"
                --assert make bitset! #{0000000000010000000000000648} = to bitset! %/file/
        --test-- "to-bitset!-binary!"
                --assert make bitset! #{} = to bitset! #{}
        --test-- "to-bitset!-binary!"
                --assert make bitset! #{616263} = to bitset! #{616263}
        --test-- "to-bitset!-block!"
                --assert make bitset! #{} = to bitset! []
        --test-- "to-bitset!-block!"
                --assert make bitset! #{60} = to bitset! [1 2]
        --test-- "to-bitset!-block!"
                --assert make bitset! #{70} = to bitset! [1 2 3]
        --test-- "to-bitset!-block!"
                --assert make bitset! #{00000000000000000000000060} = to bitset! ["a" "b"]
;       --test-- "to-bitset!-tag!"
;               --assert make bitset! #{00000000000000000000000040} = to bitset! <a>
;       --test-- "to-bitset!-email!"
;               --assert make bitset! #{0000000000000000800000002201} = to bitset! foo@boo
===end-group===


~~~end-file~~~
