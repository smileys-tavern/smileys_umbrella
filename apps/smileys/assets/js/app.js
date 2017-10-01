// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import $ from "jquery"
import { Channels } from "./socket"
import { Post } from "./post"
import { Room } from "./room"
import { Cache } from "./cache"
import { User } from "./user"

export var App = {

	run: function() {
		Channels.init()

		Post.init()

		User.init()

		Room.init()

		var that = this

		$('.menu-toggle').on('click', function(){
			that.toggleMenu()
		})
	},

	toggleMenu: function() {
		if ($('.sidebar').css("display") == "block") {
			$('.sidebar').css("display", "none")
		} else {
			$('.sidebar').css("display", "block")
		}
	},

	tempAlert: function(text) {
		$('.alert-temp').html(text)
		$('.alert-temp').show()

		setTimeout(function() { $('.alert-temp').hide() }, 4000)
	}
}