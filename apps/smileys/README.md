# Smileys Pub

A phoenix framework based community website.  The following services are used and to get the full site running and most are not optional.  Though toggles are on the development todo list to stub any service in.


## Smileys Web Setup

After all services setup; to start server (instructions copied from any phoenix setup):

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Postgres is Smileys main data store but other sql solutions may possibly work.  The recursive thread query may be the least likey to work with other solutions.


## Cloudinary

Handles image hosting for smileys internal uploads. An api key, secret and cloud name will be required to set it up.


## Sphinx Search

A service that indexes the database for the use of search.  Currently only the site search on smileys.pub and the api make use of it.  It can be set up as a remote service or run on the same machine.  It is presently optional to set up for smileys to work.  Requires a host and port be configured.


## Email / Coherence / Guardian

Smileys emails a confirmation message for registrations if the user uses email signup. Email setup requires Bamboo SMTP adapter configuration set up and coherence mailer config (smileys.pub is using sendgrid). Coherence provides generated forms for login / registration / logout etc and a lot of infrastructure for handling sessions.  Guardian is our access provider and helps store the user in the session and authenticate socket and web requests.  Both coherence and guardian have a few configuration options needed, most importantly guardians secret key.


## Orient DB

This is experimental and for use with future features. A graph database separate from the main database for users to build up if they need to while creating bartools.  Not much need be mentioned yet and it is entirely optional and only should be installed if for developing purposes. The intent though briefly is to 
allow semi-restricted access to a graph database so users can create features such as user connections or other info for analysis.