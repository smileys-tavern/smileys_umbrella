# Smileys Caretaker

Smileys Caretaker is a processes service (think CRON).  It takes care of time oriented chores such as decaying old posts.  It doesn't do much yet but in the future it will probably also take care of things such as search trend analysis to respond with increased indexing for events.

Note that using Phoenix is huge overkill at the moment. It can either be scaled back and just use a basic supervisor, or left as is since in the future other features of phoenix may come in handy, such as broadcast to the current smileys channels.

To start your Phoenix server (copied from phoenix):

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4002`](http://localhost:4002) from your browser. Note that in live production there is no reason to give this server access to the outside world.  There is also no reason for this to be run as a webserver at all.  It's a rush job and only needs the BEAM to be useful.
