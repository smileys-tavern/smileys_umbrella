## SmileysUmbrella

The umbrella contains all (and only) the deployable services that comprise the Smiley's experience.  Setting it up to run locally can be straightforward but be a lot of work the first time probably, as some services may be unfamiliar.


### Smileys

The smileys.pub website.  Contains routing and some logic for the service of the site.


### Smileysapi

The api.smileys.pub api that provides a GraphQL interface to access many of the same features of the site.


### Smileysprocesses

The process service.  This runs Cron style jobs on the same VM as the api and website. Example, it handles post deterioration so that stale content gets lowered.


### Smileysbartools (future)

Site for browsing bartools, the tools used to augment posts and site experience.


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
MIX_ENV=prod mix release --env=prod --name=smileyscaretaker
```

### On subsequent releases:
```
MIX_ENV=prod mix release --env=prod --upgrade --name=smileys
```
```
MIX_ENV=prod mix release --env=prod --upgrade --name=smileysapi
```
```
MIX_ENV=prod mix release --env=prod --upgrade --name=smileyscaretaker
```


### Releasing the releases

TODO


## Smileys Future?

Here are some desired features that may be given priority soon.

### Image transformation options

When uploading through cloudinary API it is possible to provide cropping, rotation, borders, circular images, and more.  This feature would involve adding an image preview to the create post page and a set of controls in an Elm widget.

### Smiley's Cache

Smileys would benefit enormously in scale by utilizing a distributed cache.  Nebulex (https://github.com/cabol/nebulex) looks like an excellent candidate.

### Bartools

A complex feature warranting it's own design doc.  This would be the equivalent of providing an app interface for the site.  Users could augment their post with reusable tools for doing things such as: analyzing provided nodes in tags (accomplishing things like determining connections and edge scores between related data, like determining if a news article has compromised sources), altering the style of the page, providing a poll.  These are a few ideas so far but the infrastructure is early.

### Revisit point algorithm

The current reputation based algorithm is fairly untested and should be modularized and then visited for potential strategy shifts. In case of code forks, a modularized system with an interface should allow for different strategies to be swapped in.  The objective at Smileys itself is it operates like a pub, which is not a fair and even democracy. People only want to listen to people that have something half interesting to say and there will always be a fair shake of social connectors, humerous folk and revolutionaries etc.. we should make sure folks subscriptions to the right loudmouths pay out properly and not promote a cycle of echo chambers and risk-free conversation; while the haters and newbies are around but are somewhat muted until they learn to contribute.

### Feature Toggles

We need configurable toggles for many of smileys futures, so that specialists and hobbyists can more easily set up locally. For example a postgres off switch would allow a set of data to be stubbed in. Or a sphinx toggle would allow only a few test searches to return faked results. Other candidates are orientdb, cloudinary (image uploading), and authentication. A rough toggle is already present in the api for the graph database.

### Mod tools

Smiley's will need more for sure.  Mods and Admins only have a few controls over pages at the moment. If it comes up I will rely on feedback for this.

### User to User communication

Some kind of direct to user thread or chat service will be needed.  Almost all the pieces already exist to go either way so it just needs to be consistant with Smiley's principles to be a good feature idea.
