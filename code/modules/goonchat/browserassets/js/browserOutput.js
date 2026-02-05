/**
 * Goonchat Browser Output - Vanilla JS Refactor
 * Removed jQuery and json2 dependencies
 */

// Utility functions
const escaper = encodeURIComponent;
const decoder = decodeURIComponent;

// Error handler
window.onerror = function (msg, url, line, col, error) {
	if (document.location.href.indexOf("proc=debug") <= 0) {
		let extra = col ? " | column: " + col : "";
		extra += error ? " | error: " + error : "";
		extra += navigator.userAgent
			? " | user agent: " + navigator.userAgent
			: "";
		const debugLine =
			"Error: " + msg + " | url: " + url + " | line: " + line + extra;
		window.location =
			"?_src_=chat&proc=debug&param[error]=" + escaper(debugLine);
	}
	return true;
};

// Global state
window.status = "Output";
let $messages,
	$subOptions,
	$subAudio,
	$selectedSub,
	$contextMenu,
	$filterMessages,
	$last_message;

const opts = {
	messageCount: 0,
	messageLimit: 200,
	scrollSnapTolerance: 10,
	clickTolerance: 10,
	imageRetryDelay: 50,
	imageRetryLimit: 50,
	popups: 0,
	wasd: false,
	priorChatHeight: 0,
	restarting: false,
	darkmode: false,
	selectedSubLoop: null,
	suppressSubClose: false,
	highlightTerms: [],
	highlightLimit: 10,
	highlightColor: "#FFFF00",
	pingDisabled: true,
	lastPang: 0,
	pangLimit: 35000,
	pingTime: 0,
	pongTime: 0,
	noResponse: false,
	noResponseCount: 0,
	mouseDownX: null,
	mouseDownY: null,
	preventFocus: false,
	clientDataLimit: 5,
	clientData: [],
	volumeUpdateDelay: 5000,
	volumeUpdating: false,
	updatedVolume: 0,
	musicStartAt: 0,
	musicEndAt: 0,
	defaultMusicVolume: 25,
	messageCombining: false,
};

let replaceRegexes = {};

// Helper functions
function clamp(val, min, max) {
	return Math.max(min, Math.min(val, max));
}

function outerHTML(el) {
	const wrap = document.createElement("div");
	wrap.appendChild(el.cloneNode(true));
	return wrap.innerHTML;
}

// Linkify functions
function linkify(parent, insertBefore, text) {
	let start = 0;
	let match;
	const regex =
		/(?:(?:https?:\/\/)|(?:www\.))(?:[^ ]*?\.[^ ]*?)+[-A-Za-z0-9+&@#\/%?=~_|$!:,.;()]+/gi;
	while ((match = regex.exec(text)) !== null) {
		parent.insertBefore(
			document.createTextNode(text.substring(start, match.index)),
			insertBefore,
		);
		let href = match[0];
		if (!/^https?:\/\//i.test(match[0])) {
			href = "http://" + match[0];
		}
		const link = document.createElement("a");
		link.href = href;
		link.textContent = match[0];
		parent.insertBefore(link, insertBefore);
		start = regex.lastIndex;
	}
	if (start !== 0) {
		parent.insertBefore(
			document.createTextNode(text.substring(start)),
			insertBefore,
		);
		parent.removeChild(insertBefore);
	}
}

function linkify_node(node) {
	const children = node.childNodes;
	for (let i = children.length - 1; i >= 0; --i) {
		const child = children[i];
		if (child.nodeType === Node.TEXT_NODE) {
			linkify(node, child, child.textContent);
		} else if (child.nodeName !== "A" && child.nodeName !== "a") {
			linkify_node(child);
		}
	}
}

function byondDecode(message) {
	message = message.replace(/\+/g, "%20");
	try {
		message = decodeURIComponent(message);
	} catch (err) {
		message = unescape(message);
	}
	return message;
}

function replaceRegex(el) {
	const regexName = el.getAttribute("replaceRegex");
	const selectedRegex = replaceRegexes[regexName];
	if (selectedRegex) {
		el.innerHTML = el.innerHTML.replace(selectedRegex[0], selectedRegex[1]);
	}
	el.removeAttribute("replaceRegex");
}

function addHighlightMarkup(match) {
	let extra = "";
	if (opts.highlightColor) {
		extra = ' style="background-color: ' + opts.highlightColor + '"';
	}
	return '<span class="highlight"' + extra + ">" + match + "</span>";
}

function highlightTerms(el) {
	if (el.children.length > 0) {
		for (let h = 0; h < el.children.length; h++) {
			highlightTerms(el.children[h]);
		}
	}

	let hasTextNode = false;
	for (let node = 0; node < el.childNodes.length; node++) {
		if (el.childNodes[node].nodeType === 3) {
			hasTextNode = true;
			break;
		}
	}

	if (hasTextNode) {
		let newText = "";
		for (let c = 0; c < el.childNodes.length; c++) {
			if (el.childNodes[c].nodeType === 3) {
				const words = el.childNodes[c].data.split(" ");
				for (let w = 0; w < words.length; w++) {
					let newWord = null;
					for (let i = 0; i < opts.highlightTerms.length; i++) {
						if (
							opts.highlightTerms[i] &&
							words[w]
								.toLowerCase()
								.indexOf(opts.highlightTerms[i].toLowerCase()) >
								-1
						) {
							newWord = words[w]
								.replace("<", "&lt;")
								.replace(
									new RegExp(opts.highlightTerms[i], "gi"),
									addHighlightMarkup,
								);
							break;
						}
					}
					newText += newWord || words[w].replace("<", "&lt;");
					newText += w >= words.length ? "" : " ";
				}
			} else {
				newText += outerHTML(el.childNodes[c]);
			}
		}
		el.innerHTML = newText;
	}
}

function iconError() {
	const that = this;
	setTimeout(function () {
		let attempts = parseInt(that.dataset.reload_attempts) || 1;
		if (attempts > opts.imageRetryLimit) return;
		const src = that.src;
		that.src = null;
		that.src = src + "#" + attempts;
		that.dataset.reload_attempts = ++attempts;
	}, opts.imageRetryDelay);
}

// Main output function
function output(message, flag) {
	if (typeof message === "undefined") return;
	if (typeof flag === "undefined") flag = "";

	if (flag !== "internal") opts.lastPang = Date.now();

	message = byondDecode(message).trim();

	// Filter logic
	let filteredOut = false;
	if (
		opts.hasOwnProperty("showMessagesFilters") &&
		!opts.showMessagesFilters["All"].show
	) {
		const tempDiv = document.createElement("div");
		tempDiv.innerHTML = message;
		const messageEl = tempDiv.firstChild;

		if (opts.hasOwnProperty("filterHideAll") && opts.filterHideAll) {
			let internal = false;
			const messageClasses =
				messageEl && messageEl.className
					? messageEl.className.split(/\s+/)
					: [];
			for (let i = 0; i < messageClasses.length; i++) {
				if (messageClasses[i] === "internal") {
					internal = true;
					break;
				}
			}
			if (!internal) filteredOut = "All";
		} else if (messageEl) {
			const parentClasses = messageEl.className
				? messageEl.className.split(/\s+/)
				: [];
			const childClasses =
				messageEl.firstChild && messageEl.firstChild.className
					? messageEl.firstChild.className.split(/\s+/)
					: [];
			const messageClasses = parentClasses.concat(childClasses);

			for (let i = 0; i < messageClasses.length; i++) {
				const thisClass = messageClasses[i];
				for (const key in opts.showMessagesFilters) {
					if (
						key !== "All" &&
						opts.showMessagesFilters[key].show === false &&
						opts.showMessagesFilters[key].match
					) {
						for (
							let j = 0;
							j < opts.showMessagesFilters[key].match.length;
							j++
						) {
							if (
								opts.showMessagesFilters[key].match[j] ===
								thisClass
							) {
								filteredOut = key;
								break;
							}
						}
					}
					if (filteredOut) break;
				}
				if (filteredOut) break;
			}

			if (
				!filteredOut &&
				messageClasses.length === 0 &&
				!opts.showMessagesFilters["Misc"].show
			) {
				filteredOut = "Misc";
			}
		}
	}

	// Scroll handling
	let atBottom = false;
	if (!filteredOut) {
		const bodyHeight = document.body.offsetHeight;
		const messagesHeight = $messages.offsetHeight;
		const scrollPos = window.scrollY || document.documentElement.scrollTop;

		if (
			bodyHeight + scrollPos >=
			messagesHeight - opts.scrollSnapTolerance
		) {
			atBottom = true;
			const newMsgEl = document.getElementById("newMessages");
			if (newMsgEl) newMsgEl.remove();
		} else {
			const newMsgEl = document.getElementById("newMessages");
			if (newMsgEl) {
				const numEl = newMsgEl.querySelector(".number");
				let messages = parseInt(numEl.textContent) + 1;
				numEl.textContent = messages;
				if (messages === 2) {
					newMsgEl.querySelector(".messageWord").textContent += "s";
				}
			} else {
				$messages.insertAdjacentHTML(
					"afterend",
					'<a href="#" id="newMessages"><span class="number">1</span> new <span class="messageWord">message</span> <i class="icon-double-angle-down"></i></a>',
				);
			}
		}
	}

	opts.messageCount++;

	if (opts.messageCount >= opts.messageLimit) {
		const firstChild = $messages.querySelector("div.entry:first-child");
		if (firstChild) firstChild.remove();
		opts.messageCount--;
	}

	const entry = document.createElement("div");
	entry.innerHTML = message;
	const trimmed_message = entry.textContent || entry.innerText || "";

	let handled = false;
	if (opts.messageCombining) {
		const lastMessage = $messages.querySelector("div.entry:last-child");
		if (lastMessage && $last_message && $last_message === trimmed_message) {
			let badge = lastMessage.querySelector(".r");
			if (badge) {
				badge.remove();
				badge.textContent = parseInt(badge.textContent) + 1;
			} else {
				badge = document.createElement("span");
				badge.className = "r";
				badge.textContent = "2";
			}
			lastMessage.innerHTML = message;
			lastMessage
				.querySelectorAll("[replaceRegex]")
				.forEach(replaceRegex);
			lastMessage.appendChild(badge);
			opts.messageCount--;
			handled = true;
		}
	}

	if (!handled) {
		entry.className = "entry";
		if (filteredOut) {
			entry.className += " hidden";
			entry.dataset.filter = filteredOut;
		}

		entry.querySelectorAll("[replaceRegex]").forEach(replaceRegex);
		$last_message = trimmed_message;
		$messages.appendChild(entry);

		entry.querySelectorAll("img.icon").forEach((img) => {
			img.addEventListener("error", iconError);
		});

		const to_linkify = entry.querySelectorAll(".linkify");
		to_linkify.forEach(linkify_node);

		if (opts.highlightTerms && opts.highlightTerms.length > 0) {
			highlightTerms(entry);
		}
	}

	if (!filteredOut && atBottom) {
		window.scrollTo(0, $messages.offsetHeight);
	}
}

function internalOutput(message, flag) {
	output(escaper(message), flag);
}

function runByond(uri) {
	window.location = uri;
}

// Cookie functions
function setCookie(cname, cvalue, exdays) {
	cvalue = escaper(cvalue);
	const d = new Date();
	d.setTime(d.getTime() + exdays * 24 * 60 * 60 * 1000);
	document.cookie =
		cname + "=" + cvalue + "; expires=" + d.toUTCString() + "; path=/";
}

function getCookie(cname) {
	const name = cname + "=";
	const ca = document.cookie.split(";");
	for (let i = 0; i < ca.length; i++) {
		let c = ca[i].trim();
		if (c.indexOf(name) === 0) {
			return decoder(c.substring(name.length));
		}
	}
	return "";
}

function rgbToHex(R, G, B) {
	return toHex(R) + toHex(G) + toHex(B);
}
function toHex(n) {
	n = parseInt(n, 10);
	if (isNaN(n)) return "00";
	n = Math.max(0, Math.min(n, 255));
	return (
		"0123456789ABCDEF".charAt((n - (n % 16)) / 16) +
		"0123456789ABCDEF".charAt(n % 16)
	);
}

function swap() {
	if (opts.darkmode) {
		document.getElementById("sheetofstyles").href = "browserOutput.css";
		opts.darkmode = false;
		runByond("?_src_=chat&proc=swaptolightmode");
	} else {
		document.getElementById("sheetofstyles").href = "browserOutput.css";
		opts.darkmode = true;
		runByond("?_src_=chat&proc=swaptodarkmode");
	}
	setCookie("darkmode", opts.darkmode ? "true" : "false", 365);
}

function handleClientData(ckey, ip, compid) {
	const currentData = { ckey, ip, compid };
	if (opts.clientData && opts.clientData.length > 0) {
		runByond(
			"?_src_=chat&proc=analyzeClientData&param[cookie]=" +
				JSON.stringify({ connData: opts.clientData }),
		);

		for (let i = 0; i < opts.clientData.length; i++) {
			const saved = opts.clientData[i];
			if (
				currentData.ckey === saved.ckey &&
				currentData.ip === saved.ip &&
				currentData.compid === saved.compid
			) {
				return;
			}
		}

		if (opts.clientData.length >= opts.clientDataLimit) {
			opts.clientData.shift();
		}
	} else {
		runByond("?_src_=chat&proc=analyzeClientData&param[cookie]=none");
	}

	opts.clientData.push(currentData);
	setCookie("connData", JSON.stringify(opts.clientData), 365);
}

function ehjaxCallback(data) {
	opts.lastPang = Date.now();
	if (data === "softPang") {
		return;
	} else if (data === "pang") {
		opts.pingCounter = 0;
		opts.pingTime = Date.now();
		runByond("?_src_=chat&proc=ping");
	} else if (data === "pong") {
		if (opts.pingDisabled) return;
		opts.pongTime = Date.now();
		let pingDuration = Math.ceil((opts.pongTime - opts.pingTime) / 2);
		document.getElementById("pingMs").textContent = pingDuration + "ms";
		pingDuration = Math.min(pingDuration, 255);
		const red = pingDuration;
		const green = 255 - pingDuration;
		const hex = rgbToHex(red, green, 0);
		document.getElementById("pingDot").style.color = "#" + hex;
	} else if (data === "roundrestart") {
		opts.restarting = true;
		internalOutput(
			'<div class="connectionClosed internal restarting">The connection has been closed because the server is restarting. Please wait while you automatically reconnect.</div>',
			"internal",
		);
	} else if (data === "stopMusic") {
		document.getElementById("adminMusic").src = "";
	} else {
		let dataJ;
		try {
			dataJ = JSON.parse(data);
		} catch (e) {
			window.onerror(
				"JSON: " + e + ". " + data,
				"browserOutput.html",
				327,
			);
			return;
		}
		data = dataJ;

		if (data.clientData) {
			if (opts.restarting) {
				opts.restarting = false;
				document
					.querySelectorAll(
						".connectionClosed.restarting:not(.restored)",
					)
					.forEach((el) => {
						el.classList.add("restored");
						el.textContent =
							"The round restarted and you successfully reconnected!";
					});
			}
			if (
				!data.clientData.ckey &&
				!data.clientData.ip &&
				!data.clientData.compid
			) {
				return;
			} else {
				handleClientData(
					data.clientData.ckey,
					data.clientData.ip,
					data.clientData.compid,
				);
			}
			sendVolumeUpdate();
		} else if (data.adminMusic) {
			if (typeof data.adminMusic === "string") {
				let adminMusic = byondDecode(data.adminMusic);
				let bindLoadedData = false;
				adminMusic = (adminMusic.match(/https?:\/\/\S+/) || [""])[0];

				const audioEl = document.getElementById("adminMusic");
				if (data.musicRate) {
					const newRate = Number(data.musicRate);
					if (newRate) audioEl.defaultPlaybackRate = newRate;
				} else {
					audioEl.defaultPlaybackRate = 1.0;
				}

				if (data.musicSeek) {
					opts.musicStartAt = Number(data.musicSeek) || 0;
					bindLoadedData = true;
				} else {
					opts.musicStartAt = 0;
				}

				if (data.musicHalt) {
					opts.musicEndAt = Number(data.musicHalt) || null;
					bindLoadedData = true;
				}

				if (bindLoadedData) {
					audioEl.addEventListener(
						"loadeddata",
						adminMusicLoadedData,
						{ once: true },
					);
				}
				audioEl.src = adminMusic;
				audioEl.play();
			}
		} else if (data.syncRegex) {
			for (const i in data.syncRegex) {
				const regexData = data.syncRegex[i];
				replaceRegexes[i] = [
					new RegExp(regexData[0], regexData[1]),
					regexData[2],
				];
			}
		}
	}
}

function createPopup(contents, width) {
	opts.popups++;
	const popupHtml =
		'<div class="popup" id="popup' +
		opts.popups +
		'" style="width: ' +
		width +
		'px;">' +
		contents +
		' <a href="#" class="close"><i class="icon-remove"></i></a></div>';
	document.body.insertAdjacentHTML("beforeend", popupHtml);

	const popup = document.getElementById("popup" + opts.popups);
	const height = popup.offsetHeight;
	popup.style.height = height + "px";
	popup.style.margin = "-" + height / 2 + "px 0 0 -" + width / 2 + "px";

	popup.querySelector(".close").addEventListener("click", function (e) {
		e.preventDefault();
		popup.remove();
	});
}

function toggleWasd(state) {
	opts.wasd = state === "on";
}

function sendVolumeUpdate() {
	opts.volumeUpdating = false;
	if (opts.updatedVolume) {
		runByond(
			"?_src_=chat&proc=setMusicVolume&param[volume]=" +
				opts.updatedVolume,
		);
	}
}

function adminMusicEndCheck() {
	const audioEl = document.getElementById("adminMusic");
	if (opts.musicEndAt && audioEl.currentTime >= opts.musicEndAt) {
		audioEl.removeEventListener("timeupdate", adminMusicEndCheck);
		audioEl.pause();
		audioEl.src = "";
	}
}

function adminMusicLoadedData() {
	const audioEl = document.getElementById("adminMusic");
	if (
		opts.musicStartAt &&
		(audioEl.duration === Infinity || opts.musicStartAt <= audioEl.duration)
	) {
		audioEl.currentTime = opts.musicStartAt;
	}
	if (opts.musicEndAt) {
		audioEl.addEventListener("timeupdate", adminMusicEndCheck);
	}
}

// Slide animation helpers
function slideUp(el, callback) {
	el.style.transition = "height 0.2s ease-out";
	el.style.height = el.offsetHeight + "px";
	el.offsetHeight; // Force reflow
	el.style.height = "0";
	el.style.overflow = "hidden";
	setTimeout(() => {
		el.style.display = "none";
		el.style.height = "";
		el.style.overflow = "";
		el.style.transition = "";
		el.classList.remove("scroll");
		if (callback) callback();
	}, 200);
}

function slideDown(el, callback) {
	el.style.display = "block";
	el.style.overflow = "hidden";
	const height = el.scrollHeight;
	el.style.height = "0";
	el.style.transition = "height 0.2s ease-out";
	el.offsetHeight; // Force reflow
	el.style.height = height + "px";
	setTimeout(() => {
		el.style.height = "";
		el.style.overflow = "";
		el.style.transition = "";
		if (callback) callback();
	}, 200);
}

function startSubLoop() {
	if (opts.selectedSubLoop) clearInterval(opts.selectedSubLoop);
	return setInterval(function () {
		if (!opts.suppressSubClose && $selectedSub.style.display !== "none") {
			slideUp($selectedSub);
			clearInterval(opts.selectedSubLoop);
		}
	}, 5000);
}

function handleToggleClick($sub, $toggle) {
	if ($selectedSub !== $sub && $selectedSub.style.display !== "none") {
		slideUp($selectedSub);
	}
	$selectedSub = $sub;
	if ($selectedSub.style.display !== "none") {
		slideUp($selectedSub);
		clearInterval(opts.selectedSubLoop);
	} else {
		slideDown($selectedSub, function () {
			const windowHeight = window.innerHeight;
			const toggleHeight = $toggle.offsetHeight;
			const priorSubHeight = $selectedSub.offsetHeight;
			const newSubHeight = windowHeight - toggleHeight;
			$selectedSub.style.height = newSubHeight + "px";
			if (priorSubHeight > newSubHeight) {
				$selectedSub.classList.add("scroll");
			}
		});
		opts.selectedSubLoop = startSubLoop();
	}
}

// DOM Ready
document.addEventListener("DOMContentLoaded", function () {
	$messages = document.getElementById("messages");
	$subOptions = document.getElementById("subOptions");
	$subAudio = document.getElementById("subAudio");
	$selectedSub = $subOptions;

	// Controller loop
	setInterval(function () {
		if (opts.lastPang + opts.pangLimit < Date.now() && !opts.restarting) {
			if (!opts.noResponse) {
				opts.noResponse = true;
				opts.noResponseCount++;
			}
		} else if (opts.noResponse) {
			opts.noResponse = false;
		}
	}, 2000);

	// Load saved config
	const savedConfig = {
		fontsize: getCookie("fontsize"),
		spingDisabled: getCookie("pingdisabled"),
		shighlightTerms: getCookie("highlightterms"),
		shighlightColor: getCookie("highlightcolor"),
		smusicVolume: getCookie("musicVolume"),
		smessagecombining: getCookie("messagecombining"),
		sdarkmode: getCookie("darkmode"),
	};

	if (savedConfig.fontsize) {
		$messages.style.fontSize = savedConfig.fontsize;
		internalOutput(
			'<span class="internal boldnshit">Loaded font size setting of: ' +
				savedConfig.fontsize +
				"</span>",
			"internal",
		);
	}
	if (savedConfig.sdarkmode === "true") {
		swap();
	}
	if (savedConfig.spingDisabled === "true") {
		opts.pingDisabled = true;
		document.getElementById("ping").style.display = "none";
	}
	if (savedConfig.shighlightTerms) {
		try {
			const savedTerms = JSON.parse(savedConfig.shighlightTerms);
			opts.highlightTerms = savedTerms;
		} catch (e) {}
	}
	if (savedConfig.shighlightColor) {
		opts.highlightColor = savedConfig.shighlightColor;
	}
	if (savedConfig.smusicVolume) {
		const newVolume = clamp(parseInt(savedConfig.smusicVolume), 0, 100);
		document.getElementById("adminMusic").volume = newVolume / 100;
		document.getElementById("musicVolume").value = newVolume;
		opts.updatedVolume = newVolume;
		sendVolumeUpdate();
	} else {
		document.getElementById("adminMusic").volume =
			opts.defaultMusicVolume / 100;
	}
	if (savedConfig.smessagecombining) {
		opts.messageCombining = savedConfig.smessagecombining !== "false";
	}

	// Load client data cookie
	const dataCookie = getCookie("connData");
	if (dataCookie) {
		try {
			opts.clientData = JSON.parse(dataCookie);
		} catch (e) {}
	}

	// Event listeners
	document.body.addEventListener("click", function (e) {
		if (e.target.tagName === "A") e.preventDefault();
	});

	document.body.addEventListener("mousedown", function (e) {
		if ($contextMenu) {
			$contextMenu.style.display = "none";
			return false;
		}

		const target = e.target;
		if (
			target.tagName === "A" ||
			target.closest("a") ||
			target.tagName === "INPUT" ||
			target.tagName === "TEXTAREA"
		) {
			opts.preventFocus = true;
		} else {
			opts.preventFocus = false;
			opts.mouseDownX = e.pageX;
			opts.mouseDownY = e.pageY;
		}
	});

	$messages.addEventListener("mousedown", function () {
		if ($selectedSub && $selectedSub.style.display !== "none") {
			slideUp($selectedSub);
			clearInterval(opts.selectedSubLoop);
		}
	});

	document.body.addEventListener("mouseup", function (e) {
		if (
			!opts.preventFocus &&
			e.pageX >= opts.mouseDownX - opts.clickTolerance &&
			e.pageX <= opts.mouseDownX + opts.clickTolerance &&
			e.pageY >= opts.mouseDownY - opts.clickTolerance &&
			e.pageY <= opts.mouseDownY + opts.clickTolerance
		) {
			opts.mouseDownX = null;
			opts.mouseDownY = null;
			runByond("byond://winset?mapwindow.map.focus=true");
		}
	});

	$messages.addEventListener("click", function (e) {
		if (e.target.tagName === "A") {
			const href = e.target.getAttribute("href");
			e.target.classList.add("visited");
			if (
				href[0] === "?" ||
				(href.length >= 8 && href.substring(0, 8) === "byond://")
			) {
				runByond(href);
			} else {
				runByond("?action=openLink&link=" + escaper(href));
			}
		}
	});

	document.body.addEventListener("keydown", function (e) {
		if (e.target.nodeName === "INPUT" || e.target.nodeName === "TEXTAREA")
			return;
		if (e.ctrlKey || e.altKey || e.shiftKey) return;

		e.preventDefault();
		const k = e.which;

		if (k === 113) {
			// F2
			runByond("byond://winset?screenshot=auto");
			internalOutput("Screenshot taken", "internal");
		}

		runByond("byond://winset?mapwindow.map.focus=true");
		return false;
	});

	window.addEventListener("resize", function () {
		if (window.innerHeight !== opts.priorChatHeight) {
			window.scrollTo(0, $messages.offsetHeight);
			opts.priorChatHeight = window.innerHeight;
		}
	});

	// Options interface events
	document.body.addEventListener("click", function (e) {
		if (e.target.id === "newMessages" || e.target.closest("#newMessages")) {
			e.preventDefault();
			window.scrollTo(0, $messages.offsetHeight);
			const el = document.getElementById("newMessages");
			if (el) el.remove();
			runByond("byond://winset?mapwindow.map.focus=true");
		}
	});

	document
		.getElementById("toggleOptions")
		?.addEventListener("click", function () {
			handleToggleClick($subOptions, this);
		});

	document.getElementById("darkmodetoggle")?.addEventListener("click", swap);

	document
		.getElementById("toggleAudio")
		?.addEventListener("click", function () {
			handleToggleClick($subAudio, this);
		});

	document.querySelectorAll(".sub, .toggle").forEach((el) => {
		el.addEventListener("mouseenter", () => (opts.suppressSubClose = true));
		el.addEventListener(
			"mouseleave",
			() => (opts.suppressSubClose = false),
		);
	});

	document
		.getElementById("decreaseFont")
		?.addEventListener("click", function () {
			savedConfig.fontsize =
				Math.max(parseInt(savedConfig.fontsize || 13) - 1, 1) + "px";
			$messages.style.fontSize = savedConfig.fontsize;
			setCookie("fontsize", savedConfig.fontsize, 365);
			internalOutput(
				'<span class="internal boldnshit">Font size set to ' +
					savedConfig.fontsize +
					"</span>",
				"internal",
			);
		});

	document
		.getElementById("increaseFont")
		?.addEventListener("click", function () {
			savedConfig.fontsize =
				parseInt(savedConfig.fontsize || 13) + 1 + "px";
			$messages.style.fontSize = savedConfig.fontsize;
			setCookie("fontsize", savedConfig.fontsize, 365);
			internalOutput(
				'<span class="internal boldnshit">Font size set to ' +
					savedConfig.fontsize +
					"</span>",
				"internal",
			);
		});

	document
		.getElementById("togglePing")
		?.addEventListener("click", function () {
			const pingEl = document.getElementById("ping");
			if (opts.pingDisabled) {
				pingEl.style.display = "";
				opts.pingDisabled = false;
			} else {
				pingEl.style.display = "none";
				opts.pingDisabled = true;
			}
			setCookie(
				"pingdisabled",
				opts.pingDisabled ? "true" : "false",
				365,
			);
		});

	document.getElementById("saveLog")?.addEventListener("click", function () {
		const date = new Date();
		const fname =
			"Chat Log " +
			date.getFullYear() +
			"-" +
			String(date.getMonth() + 1).padStart(2, "0") +
			"-" +
			String(date.getDate()).padStart(2, "0") +
			" " +
			String(date.getHours()).padStart(2, "0") +
			String(date.getMinutes()).padStart(2, "0") +
			String(date.getSeconds()).padStart(2, "0") +
			".html";

		fetch("browserOutput_white.css")
			.then((response) => response.text())
			.then((styleData) => {
				const blob = new Blob(
					[
						"<head><title>Chat Log</title><style>",
						styleData,
						"</style></head><body>",
						$messages.innerHTML,
						"</body>",
					],
					{ type: "text/html;charset=utf-8" },
				);

				const link = document.createElement("a");
				link.href = URL.createObjectURL(blob);
				link.download = fname;
				link.click();
				URL.revokeObjectURL(link.href);
			});
	});

	document
		.getElementById("highlightTerm")
		?.addEventListener("click", function () {
			if (document.querySelector(".popup .highlightTerm")) return;

			let termInputs = "";
			for (let i = 0; i < opts.highlightLimit; i++) {
				termInputs +=
					'<div><input type="text" name="highlightTermInput' +
					i +
					'" id="highlightTermInput' +
					i +
					'" maxlength="255" value="' +
					(opts.highlightTerms[i] || "") +
					'" /></div>';
			}
			const popupContent =
				'<div class="head">String Highlighting</div>' +
				'<div class="highlightPopup" id="highlightPopup">' +
				"<div>Choose up to " +
				opts.highlightLimit +
				" strings that will highlight the line when they appear in chat.</div>" +
				'<form id="highlightTermForm">' +
				termInputs +
				'<div><input type="text" name="highlightColor" id="highlightColor" style="background-color: ' +
				(opts.highlightColor || "#FFFF00") +
				'" value="' +
				(opts.highlightColor || "#FFFF00") +
				'" maxlength="7" /></div>' +
				'<div><input type="submit" name="highlightTermSubmit" id="highlightTermSubmit" value="Save" /></div>' +
				"</form></div>";
			createPopup(popupContent, 250);
		});

	document.body.addEventListener("keyup", function (e) {
		if (e.target.id === "highlightColor") {
			const color = e.target.value.trim();
			if (color && color.charAt(0) === "#") {
				e.target.style.backgroundColor = color;
			}
		}
	});

	document.body.addEventListener("submit", function (e) {
		if (e.target.id === "highlightTermForm") {
			e.preventDefault();

			for (let count = 0; count < opts.highlightLimit; count++) {
				const input = document.getElementById(
					"highlightTermInput" + count,
				);
				if (input) {
					const term = input.value.trim();
					opts.highlightTerms[count] =
						term === "" ? null : term.toLowerCase();
				}
			}

			const colorInput = document.getElementById("highlightColor");
			const color = colorInput.value.trim();
			opts.highlightColor =
				color === "" || color.charAt(0) !== "#" ? "#FFFF00" : color;

			const popup = document
				.getElementById("highlightPopup")
				?.closest(".popup");
			if (popup) popup.remove();

			setCookie(
				"highlightterms",
				JSON.stringify(opts.highlightTerms),
				365,
			);
			setCookie("highlightcolor", opts.highlightColor, 365);
		}
	});

	document
		.getElementById("clearMessages")
		?.addEventListener("click", function () {
			$messages.innerHTML = "";
			opts.messageCount = 0;
		});

	const musicVolumeSpan = document.getElementById("musicVolumeSpan");
	musicVolumeSpan?.addEventListener("mouseenter", function () {
		document.getElementById("musicVolumeText")?.classList.add("hidden");
		document.getElementById("musicVolume")?.classList.remove("hidden");
	});
	musicVolumeSpan?.addEventListener("mouseleave", function () {
		document.getElementById("musicVolume")?.classList.add("hidden");
		document.getElementById("musicVolumeText")?.classList.remove("hidden");
	});

	document
		.getElementById("musicVolume")
		?.addEventListener("change", function () {
			const newVolume = clamp(parseInt(this.value), 0, 100);
			document.getElementById("adminMusic").volume = newVolume / 100;
			setCookie("musicVolume", newVolume, 365);
			opts.updatedVolume = newVolume;
			if (!opts.volumeUpdating) {
				setTimeout(sendVolumeUpdate, opts.volumeUpdateDelay);
				opts.volumeUpdating = true;
			}
		});

	document
		.getElementById("toggleCombine")
		?.addEventListener("click", function () {
			opts.messageCombining = !opts.messageCombining;
			setCookie(
				"messagecombining",
				opts.messageCombining ? "true" : "false",
				365,
			);
		});

	document.querySelectorAll("img.icon").forEach((img) => {
		img.addEventListener("error", iconError);
	});

	// Kick everything off
	runByond("?_src_=chat&proc=doneLoading");
	const loadingEl = document.getElementById("loading");
	if (loadingEl) loadingEl.remove();
	document.getElementById("userBar").style.display = "";
	opts.priorChatHeight = window.innerHeight;
});

// Expose font size control functions for BYOND verbs
window.setFontSize = function (size) {
	// Clamp size between 10 and 30
	size = Math.max(10, Math.min(30, parseInt(size)));
	const newSize = size + "px";
	document.getElementById("messages").style.fontSize = newSize;
	setCookie("fontsize", newSize, 365);
	internalOutput(
		'<span class="internal boldnshit">Font size set to ' +
			newSize +
			"</span>",
		"internal",
	);
};

window.resetFontSize = function () {
	const newSize = "13px";
	document.getElementById("messages").style.fontSize = newSize;
	setCookie("fontsize", newSize, 365);
	internalOutput(
		'<span class="internal boldnshit">Font size reset to default (13px)</span>',
		"internal",
	);
};

window.toggleMessageCombining = function () {
	// Toggle the actual option that's used
	opts.messageCombining = !opts.messageCombining;
	// Save to cookie
	setCookie(
		"messagecombining",
		opts.messageCombining ? "true" : "false",
		365,
	);
	const status = opts.messageCombining ? "enabled" : "disabled";
	internalOutput(
		'<span class="internal boldnshit">Message combining ' +
			status +
			"</span>",
		"internal",
	);
};
