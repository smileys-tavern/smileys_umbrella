import $ from "jquery"
import { Channels } from "./socket"


export var Room = {

  init: function() {
  	let current_room = $("#room")
  	let op = $("#original-post")

  	if (current_room.length) {
  		Channels.joinRoom(current_room.data("name"), true)
  	} else if (op.length) {
  		Channels.joinRoom(op.data("room"), true)
  	}

  	if (typeof subscriptions !== 'undefined') {
  		for (var i = 0 ; i < subscriptions.length ; ++i) {
  			Channels.joinRoom(subscriptions[i])
  		}
  	}
  }
}
