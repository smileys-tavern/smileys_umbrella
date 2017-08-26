import $ from "jquery"


export var Cache = {

  userVotes: null,

  init: function() {
  },

  userUpdateVote: function(hash, direction) {
  	var today = new Date()

  	// 0 - 6
  	var dayIndex = "day" + today.getDay()

  	this.userVotes = JSON.parse(localStorage.getItem("userVotes"))

  	if (!this.userVotes) {
  		this.userVotes = {}
  	}

  	if (!this.userVotes.hasOwnProperty(dayIndex)) {
  		this.userVotes[dayIndex] = {}
  	}

  	this.userVotes[dayIndex][hash] = direction

  	localStorage.setItem("userVotes", JSON.stringify(this.userVotes))
  },

  userGetVotes: function() {
  	var flattenedVotes = {}

  	if (!this.userVotes) {
  		this.userVotes = JSON.parse(localStorage.getItem("userVotes"))
  	}

  	if (!this.userVotes) {
  		return {}
  	}
  		
	// flatten votes
	for (var i = 0 ; i < 7 ; ++i) {
		if (this.userVotes.hasOwnProperty("day" + i)) {
			$.extend(flattenedVotes, this.userVotes["day" + i])
		}
	}

  	return flattenedVotes;
  }
}
