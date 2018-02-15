## SmileysUmbrella

**NOTE: Initial cleanup complete!  There is still more cleaning but the major SmileysData refactor is complete, so future cleanup will be mixed
with the upcoming feature releases.**

The umbrella contains all (and only) the deployable services that comprise the Smiley's experience. The libraries aren't tied to any domain but smileys.pub demonstrates what the apps here do.  There are examples for api usage here http://smileys.pub/r/aboutsmileys and latest feature releases here http://smileys.pub/r/smileysupdates


### Smileys

The smileys.pub website.  Contains routing and some logic for the service of the site.  The Smileys site is a reddit-like community site with nested threads sorted by activity and voting algorithms.  There is a provided interface (behaviour) for implementing new algorithms as a work in progress (as of version 0.0.11). Smileys.pub is served across 3 servers in order to fascilitate distributed testing and is aware of the api and processes as part of the same VM.

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
  * Sphinxsearch is used here via SphinxQL (queried by giza_sphinxsearch) with an Elm front facing client reading from a channel connection. It is very fast and reliable

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


### Smileysprocesses

The process service.  This runs Cron style jobs on the same VM as the api and website. Example, it handles post deterioration so that stale content gets lowered and runs bots that parse rss feeds. In the future it would handle timed tasks on behalf of users as well. The processes is currently served on a single node but is aware of the api and site on the same VM.

* Bots can be added programmatically or to the database to scrape content. You can see them on smileys.pub as philosophybot and newsbot for example
* Vote algorithm behaviour is on timers to adjust content based on time alive


### Smileysbartools (future)

Site for browsing bartools, the tools used to augment posts and site experience.

Bartools is a planned feature later for a behavior of implementing elixir apps that can be used to augment posted content.  Things like games and polls and contracts via the voting channel could be implemented by this will be the idea.


### Deployment Tools

Gulp is used to expediate many common tasks particularly for builds and deployment.  Gulp is used in order to keep flexibility high as the setup of which services belong in which EVM's may change in the future.  Other deployment tools may work but for now gulp and some manual labour is in use until enough patterned usage needs emerge.


## Building Releases

The project is first initialized as an umbrella app but as separate releases per app in the exrm style:

### One time requirement
```
mix release.init --release-per-app
```

### Only for apps that have static assets (js/css/images):
```
cd apps/smileys/assets
```
```
./node_modules/brunch/bin/brunch build --production
```

### Back in the base dir of smileys_umbrella:
```
MIX_ENV=prod mix phx.digest
```

### First release:
```
MIX_ENV=prod mix release --env=prod --name=smileys
```
```
MIX_ENV=prod mix release --env=prod --name=smileysapi
```
```
MIX_ENV=prod mix release --env=prod --name=smileysprocesses
```

### On subsequent releases:
```
MIX_ENV=prod mix release --env=prod --upgrade --name=smileys
```
```
MIX_ENV=prod mix release --env=prod --upgrade --name=smileysapi
```
```
MIX_ENV=prod mix release --env=prod --upgrade --name=smileysprocesses
```


### Releasing the releases

TODO


## Smileys Future?

Here are some desired features that may be given priority soon.

### Collaborative editing

A difficult problem to solve and scale but well suited for Elixir/Erlang

### Image transformation options

When uploading through cloudinary API it is possible to provide cropping, rotation, borders, circular images, and more.  This feature would involve adding an image preview to the create post page and a set of controls in an Elm widget.

### Smiley's Cache

Smileys would benefit enormously in scale by utilizing a distributed cache.  Nebulex (https://github.com/cabol/nebulex) looks like an excellent candidate.

### Bartools

A complex feature warranting it's own design doc.  This would be the equivalent of providing an app interface for the site.  Users could augment their post with reusable tools for doing things such as: analyzing provided nodes in tags (accomplishing things like determining connections and edge scores between related data, like determining if a news article has compromised sources), altering the style of the page, providing a poll.  These are a few ideas so far but the infrastructure is early.

### Additional content scoring algorithms

Now that there is a behavior for them, it is a little more clear how to implement vote scoring algorithms.  Can have a few to swap in in case one is inadequate for the future.

### Feature Toggles

We need configurable toggles for many of smileys futures, so that specialists and hobbyists can more easily set up locally. For example a postgres off switch would allow a set of data to be stubbed in. Or a sphinx toggle would allow only a few test searches to return faked results. Other candidates are cloudinary (image uploading), and authentication. A rough toggle is already present in the api for the graph database which is a feature that will be taken out it appears.

### Mod tools

Smiley's will need more for sure.  Mods and Admins only have a few controls over pages at the moment. If it comes up I will rely on feedback for this.

### User to User communication

Some kind of direct to user thread or chat service will be needed.  Almost all the pieces already exist to go either way so it just needs to be consistant with Smiley's principles to be a good feature idea.