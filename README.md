## SmileysUmbrella

***NOTE*** This was a learning project; parts of it are rushed to get to other bits to test the Elixir ecosystem. Pleased to say that ecosystem is AMAZING. This project will no longer be maintained but I'll link to the new project whenever I work on it. I will transfer while refactoring any necessary code into a new project that will ditch the current javascript code for liveview. Organization of code should be much better and easier to plug and play a custom version of the site. Cheers!


### Smileys

The website project utilizing Phoenix.  Contains routing and some logic for the service of the site.  The Smileys site is a reddit-like community site with nested threads sorted by activity and voting algorithms.  There is a provided interface (behaviour) for implementing new algorithms as a work in progress (as of version 0.0.11). Smileys.pub is served across 3 servers in order to fascilitate distributed testing and is aware of the api and processes as part of the same VM.

The core functionality includes

* Room creation
  * Private Room - Only users you allow can read or post to these boards
  * Restricted Room - Anyone can read or comment, but only users you allow can post original content
  * Public Room - Anyone can read, comment or post original content
  * Age limits are allowed that will be transfered to posts
  * Can add additional moderators
  * A title and description for the room or a banner image are allowable

* Post Content
  * Content can include a mix of content including a link, image, tags, a text body with a large character limit and title (required)
  * Tags can have special meaning like embedding a video, image link or map, adding a NSFW thumbnail, or making search easier
  * Content posting has a time limit for frequency per user until they have used the site enough reputably to post more
  * Content receives a public vote that can be seen adjusting in real time, additionally there are private and alltime scores. The private score adjusts by whichever algorithm implemented and determines ranking
  * Anonymous posting is allowed in most circumstances for original content and comments

* Commenting
  * Users and Anons can post comments in response to original content
  * Comments are sorted according to algorithm the same was as Posts
  * Special functionality is availabe via /[type code]/[subject]
  * The only special functionality available at the moment is user pinging such as /u/subetei
  * Commenting in Private rooms is hidden from search and your user page

* Aggregate Pages
  * Smileys generates some of it's own content via bots in Smileysprocesses
  * The currently implemented bots scrape RSS feeds and transfer these summaries into Posts, allowing visitors to link into the full content and comment and vote on it here if they wish.
  * An example of one such is /r/news

* Email Subscriptions
  * Smileys Processes sends out emails asyncronously to every user with a subscription set
  * Subscriptions will basically send the update info available in their sidebar on-site, updating a user on:
    * Shoutouts from other users
    * Comment and vote activity on their very own latest posts
    * New subscribers and posts on their Subscribed to rooms

* Real Time Updates
  * All voting, comment counts and responses to your content are updated to the visitors client in real time via efficient channels
  * A rolling time window of content is kept in state at all times, so x hours of new content counts or user pings or responses to logged in users posts for example

* Search
  * Highly customizable. Right now does a basic and slightly optimized search of all site content which is indexed within 5 minutes of posting
  * Search by room, post, user
  * Sphinxsearch is used here via SphinxQL (queried by giza_sphinxsearch) with an Elm front facing client reading from a channel connection. Fast and reliable

* House Rooms
  * Accessed via /h/roomname
  * /h/all for top content site wide
  * /h/walloffame for all time upvoted content
  * These are aggregate rooms for special purpose and cannot be posted to normally


### Smileysapi

The api.smileys.pub api that provides a GraphQL interface to access many of the same features of the site.  It is in early stages (as of 0.0.2) and only has a few endpoints.  api.smileys.pub is served across 2 servers in order to fascilitate distributed testing and is aware of the website and processes as part of the same VM. Currently implemented:

* Full site content search with various filters
* Public info about user can be queried
* Posts can be queried for all publicly available data

Some work has been done to implement authentication so that content creation can be opened up but has not yet been completed.


### Building Releases

TODO: Re-doing release process as I now prefer edeliver and distillery


## Smileys Future?

Here are some desired features that may be given priority soon.

### Collaborative editing

A difficult problem to solve and scale but well suited for Elixir/Erlang

### Image transformation options

When uploading through cloudinary API it is possible to provide cropping, rotation, borders, circular images, and more.  This feature would involve adding an image preview to the create post page and a set of controls in an Elm widget.

### Additional content scoring algorithms

Now that there is a behavior for them, it is a little more clear how to implement vote scoring algorithms.  Can have a few to swap in in case one is inadequate for the future.

### Mod tools

Smiley's will need more for sure.  Mods and Admins only have a few controls over pages at the moment. If it comes up I will rely on feedback for this.

### User to User communication

Some kind of direct to user thread or chat service will be needed.  Almost all the pieces already exist to go either way so it just needs to be consistant with Smiley's principles to be a good feature idea.