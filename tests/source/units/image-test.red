Red [
	Title:   "Red image test script"
	Author:  "bitbegin"
	File: 	 %image-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "image"

img: make image! 2x2
===start-group=== "image range(integer index)"
	--test-- "image range(integer index) 1"
		--assert none = img/0
	--test-- "image range(integer index) 2"
		--assert error? try [img/0: 1.2.3]
	--test-- "image range(integer index) 3"
		--assert img/1 = 255.255.255
	--test-- "image range(integer index) 4"
		--assert 1.2.3 = img/1: 1.2.3
	--test-- "image range(integer index) 5"
		--assert img/2 = 255.255.255
	--test-- "image range(integer index) 6"
		--assert 1.2.3 = img/2: 1.2.3
	--test-- "image range(integer index) 7"
		--assert img/3 = 255.255.255
	--test-- "image range(integer index) 8"
		--assert 1.2.3 = img/3: 1.2.3
	--test-- "image range(integer index) 9"
		--assert img/4 = 255.255.255
	--test-- "image range(integer index) 10"
		--assert 1.2.3 = img/4: 1.2.3
	--test-- "image range(integer index) 11"
		--assert none = img/5
	--test-- "image range(integer index) 12"
		--assert error? try [img/5: 1.2.3]
===end-group===

img: make image! 2x2
===start-group=== "image range(pair index)"
	--test-- "image range(pair index) 1"
		--assert none = img/(0x0)
	--test-- "image range(pair index) 2"
		--assert error? try [img/(0x0): 1.2.3]
	--test-- "image range(pair index) 3"
		--assert none = img/(0x1)
	--test-- "image range(pair index) 4"
		--assert error? try [img/(0x1): 1.2.3]
	--test-- "image range(pair index) 5"
		--assert none = img/(1x0)
	--test-- "image range(pair index) 6"
		--assert error? try [img/(1x0): 1.2.3]
	--test-- "image range(pair index) 7"
		--assert img/(1x1) = 255.255.255
	--test-- "image range(pair index) 8"
		--assert 1.2.3 = img/(1x1): 1.2.3
	--test-- "image range(pair index) 9"
		--assert img/(1x2) = 255.255.255
	--test-- "image range(pair index) 10"
		--assert 1.2.3 = img/(1x2): 1.2.3
	--test-- "image range(pair index) 11"
		--assert img/(2x1) = 255.255.255
	--test-- "image range(pair index) 12"
		--assert 1.2.3 = img/(2x1): 1.2.3
	--test-- "image range(pair index) 13"
		--assert img/(2x2) = 255.255.255
	--test-- "image range(pair index) 14"
		--assert 1.2.3 = img/(2x2): 1.2.3
	--test-- "image range(pair index) 15"
		--assert none = img/(1x3)
	--test-- "image range(pair index) 16"
		--assert error? try [img/(1x3): 1.2.3]
	--test-- "image range(pair index) 17"
		--assert none = img/(3x1)
	--test-- "image range(pair index) 18"
		--assert error? try [img/(3x1): 1.2.3]
	--test-- "image range(pair index) 19"
		--assert none = img/(2x3)
	--test-- "image range(pair index) 20"
		--assert error? try [img/(2x3): 1.2.3]
	--test-- "image range(pair index) 21"
		--assert none = img/(3x2)
	--test-- "image range(pair index) 22"
		--assert error? try [img/(3x2): 1.2.3]
===end-group===

~~~end-file~~~
