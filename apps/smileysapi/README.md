# Smileys API

A phoenix framework and absinthe based API in support of Smileys Website. Pretty much the whole functionality of the site means to be represented here, however it is a work in progress.


## Smileys API Setup

After all services setup; to start server (instructions copied from any phoenix setup):

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4001`](http://localhost:4001) from your browser.

Postgres is Smileys main data store but other sql solutions may possibly work.  The recursive thread queries may be the least likey to work with other solutions.


## Sphinx Search

A service that indexes the database for the use of search.  Currently only the site search on smileys.pub and the api make use of it.  It can be set up as a remote service or run on the same machine.  It is presently optional to set up for smileys to work.  Requires a host and port be configured.


## Orient DB

This is experimental and for use with future features. A graph database separate from the main database for users to build up if they need to while creating bartools.  Not much need be mentioned yet and it is entirely optional and only should be installed if for developing purposes. The intent though briefly is to 
allow semi-restricted access to a graph database so users can create features such as user connections or other info for analysis.