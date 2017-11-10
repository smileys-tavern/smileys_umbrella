import $ from "jquery"
import {Channels} from "./socket"
import {Cache} from "./cache"
import {App} from "./app"

export var User = {

  init: function() {

  	Channels.joinUser()

  	$('body').on('click', '.room-subscribe', function(){
  		var room_name = $(this).data('room')

  		Channels.userChannel.push("subscribe", {roomname: room_name}).receive("ok", (response) => {
  			if (response.room) {
		        $('.room-subscribe').remove()

		        $('.subscriptions').append(
		          '<div class="room-link room-' + room_name + '"><a href="/r/' + room_name + '">/r/' + room_name + '</a> <span class="update"></span>' +
		          	'<span class="controls"><a href="javascript:void(0)" class="room-unsubscribe" data-room="' + room_name + '">unsub</a></span>' + 
		          	'</div>'
		        )
		    } else {
		    	App.tempAlert("15 max room subscriptions")
		    }
	    })
  	})

  	$('body').on('click', '.room-unsubscribe', function(){
  		var room_name = $(this).data('room')

  		Channels.userChannel.push("unsubscribe", {roomname: room_name}).receive("ok", (response) => {
	        $('.room-' + room_name).remove()
	    })
  	})

    $('body').on('mouseover', '.activity-count', function(){
      if ($(this).data('hover').length) {
        $(this).text($(this).text() + " " + $(this).data('hover'))
      }
    })

    $('body').on('mouseleave', '.activity-count', function(){
      var parts = $(this).text().split(" ")
      $(this).text(parts[0])
    })

  	this.showAllVotesOnPage(Cache.userGetVotes())
  },

  showAllVotesOnPage: function(votes) {
  	var currentVoteBlock = null;

  	for (var vote in votes) {
  		currentVoteBlock = $('.vote-' + vote)

  		if (currentVoteBlock.length) {
  			currentVoteBlock.find('.vote-' + votes[vote]).addClass("arrow-" + votes[vote] + "-used")
  		}
  	}
  },

  showVote: function(voteWidget, direction) {
  	voteWidget.find('.vote-' + direction).addClass("arrow-" + direction + "-used")
  },

  unshowVote: function(voteWidget, direction) {
  	voteWidget.find('.vote-' + direction).removeClass("arrow-" + direction + "-used")
  }
}
