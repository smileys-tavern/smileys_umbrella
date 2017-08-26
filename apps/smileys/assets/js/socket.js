import {Socket, Presence} from "phoenix"
import {App} from "./app"
import {Cache} from "./cache"
import {User} from "./user"
import Elm from "./smileys"
import $ from "jquery"


export var Channels = {

  socket: null,

  guardianToken: null,

  userName: null,

  roomChannels: {},

  postChannel: null,

  userChannel: null,

  ophash: null,

  elm: null,

  presences: {},

  init: function() {
  	let guardianToken = $('meta[name="guardian_token"]').attr('content');

  	let userName = $('meta[name="user_name"]').attr('content');

  	let socket = new Socket("/socket", {params: {guardian_token: guardianToken}})

  	socket.connect()

  	this.guardianToken = guardianToken

  	this.socket = socket

  	this.userName = userName

    // Now with socket connection available, start up ELM module(s)
    var elmDiv = document.getElementById('search')

    if (elmDiv) {
      this.elm = Elm.SmileysSearch.embed(elmDiv, {
          websocketUrl: socket.endPointURL().split("?")[0]
      })
    }
  },

  joinRoom: function(room_name, is_current_room) {
    // Ensure we do not join the same channel twice
    if (typeof this.roomChannels["r" + room_name] !== "undefined") {
      return;
    }

  	var that = this

  	let channel = this.socket.channel("room:" + room_name, {guardian_token: this.guardianToken})

    let listBy = (user, {}) => {
      return {
        user: user
      }
    }

  	channel.join()
  	  .receive("ok", resp => { 
        that.joinedChannel("Room " + room_name, resp) 

        channel.on("hot", payload => {
          var post = `${payload.post}`

          $('.room-' + room_name).prepend("<a href=\"" + post + "\">NEW</a>")
        });

        channel.on("vote", payload => {
          var posthash = `${payload.posthash}`
          var score = `${payload.score}`
          var result = `${payload.result}`

          var postElement = $('.vote-count-' + posthash)

          if (postElement) {
            postElement.text(score)
          }
        })

        if (is_current_room) {
          // Enable voting
          $('body').on('click', '.vote-up', function() {
            var hash = $(this).data('hash')
            var room = $(this).data('room')

            channel.push("voteup", {posthash: hash.toString(), room: room.toString()})
          })

          $('body').on('click', '.vote-down', function() {
            var hash = $(this).data('hash')
            var room = $(this).data('room')

            channel.push("votedown", {posthash: hash.toString(), room: room.toString()})
          })

          // Get Presence
          channel.on("presence_state", state => {
            var usersOnlineDiv = $(".online-users")

            if (usersOnlineDiv.length) {
              usersOnlineDiv.text(Object.keys(state).length)
            }
          })
        }
      })
  	  .receive("error", resp => { that.errorJoiningChannel("Room " + room_name, resp) }) 	

  	this.roomChannels["r" + room_name] = channel
  },

  joinPost: function(post_hash) {
    this.ophash = post_hash
  	var that = this

  	let channel = this.socket.channel("post:" + post_hash, {guardian_token: this.guardianToken})

  	channel.join()
   	  .receive("ok", resp => { 
        that.joinedChannel("Post " + post_hash, resp) 

        channel.on("activity", payload => {
          var msg = `${payload.msg}`
          var hash = `${payload.hash}`
          var ophash = `${payload.ophash}`
          var comment = $('#comment-' + hash)

          // Users latest posts
          if ($('.activity-post-' + hash).length) {
            $('.activity-post-' + hash).html(msg)
          }

          // Update level 1 comments that something in the tree was updated
          var exposedReload = false

          do {
            if (comment.data("commentdepth") == 1) {
              comment.find('.interactive').removeClass('hidden')

              exposedReload = true
            } else {
              comment = comment.prev()
            }
          } while (!exposedReload && comment.data("commentdepth"))
        })

        channel.on("vote", payload => {
          var posthash = `${payload.posthash}`
          var score = `${payload.score}`
          var result = `${payload.result}`

          var postElement = $('.vote-count-' + posthash)

          if (postElement) {
            postElement.text(score)
          }
        })
      })
  	  .receive("error", resp => { that.errorJoiningChannel("Post " + post_hash, resp) })

  	this.postChannel = channel
  },

  joinUser: function() {
  	if (this.userName) {
	  	var that = this

	  	let channel = this.socket.channel("user:" + this.userName, {guardian_token: this.guardianToken})

	  	channel.join()
	  		.receive("ok", resp => { 
          that.joinedChannel("User " + this.userName, resp) 

          channel.on("warning", payload => {
            var msg = `${payload.msg}`

            App.tempAlert(msg)
          });

          channel.on("vote", payload => {
            var direction = `${payload.direction}`
            var hash = `${payload.hash}`

            Cache.userUpdateVote(hash, direction)

            User.showVote($('.vote-' + hash), direction)
          });
        })
	  		.receive("error", resp => { that.errorJoiningChannel("User " + this.userName, resp) })

	  	this.userChannel = channel
  	} else {
  		console.log("Not logged in unable to join channel")
  	}
  },

  joinPostActivity: function(hash) {
    if (hash == this.ophash) { return }

    var that = this

    let channel = this.socket.channel("post:" + hash, {guardian_token: this.guardianToken})

    channel.join()
      .receive("ok", resp => { 
        that.joinedChannel("Post " + hash, resp) 

        channel.on("activity", payload => {
          var msg = `${payload.msg}`
          var post_hash = `${payload.hash}`

          $('.activity-post-' + post_hash).html(msg)
        })
      })
      .receive("error", resp => { that.errorJoiningChannel("Post " + hash, resp) })
  },

  joinedChannel: function(name, resp) {
  	console.log("Joined Channel " + name, resp)
  },

  errorJoiningChannel: function(name, resp) {
  	console.log("Unable to join Channel " + name, resp)
  }
}
