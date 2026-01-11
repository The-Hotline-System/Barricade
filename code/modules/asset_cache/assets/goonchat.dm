/datum/asset/group/goonchat
	children = list(
		/datum/asset/simple/jquery,
		/datum/asset/simple/purify,
		/datum/asset/simple/namespaced/goonchat,
		/datum/asset/simple/namespaced/fontawesome,
		/datum/asset/simple/namespaced/chatsovl,
		/datum/asset/simple/namespaced/roguefonts
	)

/datum/asset/spritesheet/goonchat
	name = "chat"

/datum/asset/simple/namespaced/roguefonts
	legacy = TRUE
	assets = list(
		"PixelifySans-VariableFont_wght.ttf" = 'interface/fonts/PixelifySans-VariableFont_wght.ttf',
		"pterra.ttf" = 'interface/fonts/pterra.ttf',
		"pterra.ttf" = 'interface/fonts/pterra.ttf',
		"lilgard.ttf" = 'interface/fonts/lilgard.ttf',
		"uberbit7.ttf" = 'interface/fonts/uberbit7.ttf',
		"roboto_c.ttf" = 'interface/fonts/roboto_c.ttf',
		"roboto_c_italic.ttf" = 'interface/fonts/roboto_c_italic.ttf',
		"chiseld.ttf" = 'interface/fonts/chiseld.ttf',
		"blackmoor.ttf" = 'interface/fonts/blackmoor.ttf',
		"handwrite.ttf" = 'interface/fonts/handwrite.ttf',
		"book1.ttf" = 'interface/fonts/book1.ttf',
		"book2.ttf" = 'interface/fonts/book1.ttf',
		"book3.ttf" = 'interface/fonts/book1.ttf',
		"book4.ttf" = 'interface/fonts/book1.ttf',
		"dwarf.ttf" = 'interface/fonts/languages/dwarf.ttf',
		"elf.ttf" = 'interface/fonts/languages/elf.ttf',
		"oldpsydonic.ttf" = 'interface/fonts/languages/oldpsydonic.ttf',
		"zybantine.ttf" = 'interface/fonts/languages/zybantine.ttf',
		"hell.ttf" = 'interface/fonts/languages/hell.ttf',
		"orc.ttf" = 'interface/fonts/languages/orc.ttf',
		"sand.ttf" = 'interface/fonts/languages/sand.ttf',
		"undead.ttf" = 'interface/fonts/languages/undead.ttf',

		// New pixel fonts
		"DePixelBreit.ttf" = 'interface/fonts/pixel/DePixelBreit.ttf',
		"DePixelBreitFett.ttf" = 'interface/fonts/pixel/DePixelBreitFett.ttf',
		"DePixelHalbfett.ttf" = 'interface/fonts/pixel/DePixelHalbfett.ttf',
		"DePixelIllegible.ttf" = 'interface/fonts/pixel/DePixelIllegible.ttf',
		"DePixelKlein.ttf" = 'interface/fonts/pixel/DePixelKlein.ttf',
		"DePixelSchmal.ttf" = 'interface/fonts/pixel/DePixelSchmal.ttf',

		// Typewriting
		"Not-my-Type.ttf" = 'interface/fonts/writing/Not-my-Type.ttf'
	)

/datum/asset/simple/namespaced/chatsovl
	legacy = TRUE
	assets = list(
		"chatbg-t.png" = 'code/modules/goonchat/browserassets/img/chatbg-t.png',
		"testbg.png" = 'code/modules/goonchat/browserassets/img/testbg.png',
		"chatbg-b.png" = 'code/modules/goonchat/browserassets/img/chatbg-b.png',
		"chatbg-w-ct.png" = 'code/modules/goonchat/browserassets/img/chatbg-w-ct.png',
		"chatbg-w-cb.png" = 'code/modules/goonchat/browserassets/img/chatbg-w-cb.png',
		"chatbg-w.png" = 'code/modules/goonchat/browserassets/img/chatbg-w.png',
		"chatbg-e-ct.png" = 'code/modules/goonchat/browserassets/img/chatbg-e-ct.png',
		"chatbg-e-cb.png" = 'code/modules/goonchat/browserassets/img/chatbg-e-cb.png',
		"chatbg-e.png" = 'code/modules/goonchat/browserassets/img/chatbg-e.png',
		"try6.png" = 'icons/sovlpanel/try6.png',
		"try6_btn.png" = 'icons/sovlpanel/try6_btn.png',
		"try6_border.png" = 'icons/sovlpanel/try6_border.png',
		"chatscrollbar-bg-t.png" = 'code/modules/goonchat/browserassets/img/chatscrollbar-bg-t.png',
		"chatscrollbar-bg.png" = 'code/modules/goonchat/browserassets/img/chatscrollbar-bg.png',
		"chatscrollbar-bg-b.png" = 'code/modules/goonchat/browserassets/img/chatscrollbar-bg-b.png',
		"chatscrollbar-scrolldown.png" = 'code/modules/goonchat/browserassets/img/chatscrollbar-scrolldown.png',
		"chatscrollbar-scrollup.png" = 'code/modules/goonchat/browserassets/img/chatscrollbar-scrollup.png',
		"chatscroller-b.png" = 'code/modules/goonchat/browserassets/img/chatscroller-b.png',
		"chatscroller-m.png" = 'code/modules/goonchat/browserassets/img/chatscroller-m.png',
		"chatscroller-t.png" = 'code/modules/goonchat/browserassets/img/chatscroller-t.png',
	)


/datum/asset/simple/purify
	legacy = TRUE
	assets = list(
		"purify.min.js"            = 'code/modules/goonchat/browserassets/js/purify.min.js',
	)

/datum/asset/simple/jquery
	legacy = TRUE
	assets = list(
		"jquery.min.js"            = 'code/modules/goonchat/browserassets/js/jquery.min.js',
	)

/datum/asset/simple/namespaced/goonchat
	legacy = TRUE
	assets = list(
		"json2.min.js"             = 'code/modules/goonchat/browserassets/js/json2.min.js',
		"errorHandler.js"             = 'code/modules/goonchat/browserassets/js/errorHandler.js',
		"browserOutput.js"         = 'code/modules/goonchat/browserassets/js/browserOutput.js',
		"browserOutput.css"	       = 'code/modules/goonchat/browserassets/css/browserOutput.css',
		"browserOutput_white.css"  = 'code/modules/goonchat/browserassets/css/browserOutput.css',
	)
	parents = list()

/datum/asset/simple/namespaced/fontawesome
	legacy = TRUE
	assets = list(
		"fa-regular-400.eot"  = 'html/font-awesome/webfonts/fa-regular-400.eot',
		"fa-regular-400.woff" = 'html/font-awesome/webfonts/fa-regular-400.woff',
		"fa-solid-900.eot"    = 'html/font-awesome/webfonts/fa-solid-900.eot',
		"fa-solid-900.woff"   = 'html/font-awesome/webfonts/fa-solid-900.woff',
		"font-awesome.css"    = 'html/font-awesome/css/all.min.css',
		//"v4shim.css"          = 'html/font-awesome/css/v4-shims.min.css'
	)
	parents = list("font-awesome.css" = 'html/font-awesome/css/all.min.css')
