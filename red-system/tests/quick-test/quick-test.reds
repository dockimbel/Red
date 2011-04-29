Red/System [
	Title:   "Red/System simple testing framework"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.reds
	Version: 0.2.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#include %prin-int.reds
#include %overwrite.reds

;; allocate string memory
qt-run-name:    "123456789012345678901234567890"
qt-file-name:   "123456789012345678901234567890"
qt-group-name:  "123456789012345678901234567890"
qt-test-name:   "123456789012345678901234567890"
qt-max-len:     length? qt-run-name

;; counters
qt-run: struct [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
]
qt-file: struct [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
]
;; switches
qt-group-name-not-printed: true
qt-group?: false

qt-init-run: func [] [
  qt-run/tests:     0
  qt-run/asserts:   0
  qt-run/passes:    0
  qt-run/failures:  0
]

qt-init-file: func [] [
  qt-file/tests:     0
  qt-file/asserts:   0
  qt-file/passes:    0
  qt-file/failures:  0
]

***start-run***: func[
    title [c-string!]
][
  qt-init-run
  overwrite qt-run-name title qt-max-len
  prin "***Starting*** "
  print title
  print ""
]

~~~start-file~~~: func [
  title [c-string!]
][
  qt-init-file
  prin "~~~started test~~~ "
  print title
  overwrite qt-file-name title qt-max-len
  qt-group?: false
]

===start-group===: func [
  title [c-string!]
][
  overwrite qt-group-name title qt-max-len
  qt-group?: true
]

--test--: func [
  title [c-string!]
][
  overwrite qt-test-name title qt-max-len
  qt-file/tests: qt-file/tests + 1
]

--assert: func [
  assertion [logic!]
][
  qt-file/asserts: qt-file/asserts + 1
  
  either assertion [
     qt-file/passes: qt-file/passes + 1
  ][
    qt-file/failures: qt-file/failures + 1
    if qt-group? [  
      if qt-group-name-not-printed [
        print ""
        prin "---group--- "
        print qt-group-name
        qt-group-name-not-printed: false
      ]
    ]
    prin "--test-- "
    prin qt-test-name
    print " FAILED**************"
  ]
]

===end-group===: func [] [
  qt-group-name-not-printed: true
]

~~~end-file~~~: func [] [
  print ""
  prin "~~~finished test~~~ "
  print qt-file-name
  qt-print-totals qt-file/tests
                  qt-file/asserts
                  qt-file/passes 
                  qt-file/failures
  print ""
  
  ;; update run totals
  qt-run/passes: qt-run/passes + qt-file/passes
  qt-run/asserts: qt-run/asserts + qt-file/asserts
  qt-run/failures: qt-run/failures + qt-file/failures
  qt-run/tests: qt-run/tests + qt-file/tests
]

***end-run***: func [][
  prin "***Finished*** "
  print qt-run-name
  qt-print-totals qt-run/tests
                  qt-run/asserts
                  qt-run/passes
                  qt-run/failures
]

qt-print-totals: func [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
][
  prin "  Number of Tests Performed:      "
  prin-int tests
  print ""
  prin "  Number of Assertions Performed: "
  prin-int asserts
  print ""
  prin "  Number of Assertions Passed:    "
  prin-int passes
  print ""
  prin "  Number of Assertions Failed:    "
  prin-int failures
  print ""
  if failures <> 0 [
    print "****************TEST FAILURES****************"
  ]
]


