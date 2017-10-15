'use strict'

var gulp = require('gulp');
var fs   = require('fs');
var GulpSSH  = require('gulp-ssh');
var shell = require('gulp-shell');

// Dev env settings
var dev = JSON.parse(fs.readFileSync('gulp/dev.json', 'utf8'));

// Get the list of servers we can deploy a node to
var servers = JSON.parse(fs.readFileSync('gulp/servers.json', 'utf8'));

var smileysNodes = servers.smileysWeb;

var otherNodes = servers.other;

// App settings (Context: remote server)
var nodeConfs = JSON.parse(fs.readFileSync('gulp/smileys-nodes.json', 'utf8'));


// SSH setup
var gulpSSH = [];

for (var i = 0 ; i < smileysNodes.length ; ++i) {
  var sshConfig = {
    host: smileysNodes[i].ssh,
    port: 22,
    username: 'ubuntu',
    privateKey: fs.readFileSync('/home/baggy/web/smileys-1.pem')
  };

  gulpSSH.push(new GulpSSH({
    ignoreErrors: true,
    sshConfig: sshConfig
  }));
}


gulp.task('sftp_vm_args', function(){
	smileysNodes.forEach(function(server, i) {
		return gulp.src('gulp/vm.args.' + i)
			.pipe(gulpSSH[i].sftp('write', '/home/ubuntu/vm.args'))
	});
});

gulp.task('sftp_node_sync', function(){
	smileysNodes.forEach(function(server, i) {
    var nodeConf = nodeConfs[server.name];

		return gulp.src('gulp/' + nodeConf.name + '.config.' + i)
			.pipe(gulpSSH[i].sftp('write', nodeConf.dir + nodeConf.name + '.config'));
	});
});

gulp.task('sftp_smileys', function(){
	smileysNodes.forEach(function(server, i) {
    var nodeConf = nodeConfs[server.name];

		return gulp.src('_build/prod/rel/' + nodeConf.name + '/releases/' + nodeConf.version + '/' + nodeConf.name + '.tar.gz')
			.pipe(gulpSSH[i].sftp('write', nodeConf.dir + nodeConf.name + '.tar.gz'));
	});
});

gulp.task('sftp_other', function() {
  otherNodes.forEach(function(server, i) {
    nodeConf = nodeConfgs[server.name];

    return gulp.src(nodeConf.files)
      .pipe(gulpSSH[i].sftp('write', nodeConf.dir + nodeConf.name + '.tar.gz'));
  });
});

gulp.task('create_vm_args', function(){
  for (var i = 0 ; i < smileysNodes.length ; ++i) {
    var nodeConf = nodeConfs[smileysNodes[i].name]

  	var vmArgs = '-name ' + smileysNodes[i].name + '\n\n' +
  		'-setcookie ' + nodeConf.cookie + '\n\n' +
  		'-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9155\n\n' +
  		'-config ' + nodeConf.dir + nodeConf.name + '.config\n\n' +
  		'-smp auto\n\n';

    fs.writeFile('gulp_output/vm.args.' + i, vmArgs, (err) => {
      if (err) throw err;

      console.log('gulp_output/vm.args file saved');
    });
  }
});

gulp.task('create_node_sync_config', function(){
  for (var i = 0 ; i < smileysNodes.length ; ++i) {
  	// Generating an erlang config file
  	var syncNodeConfig = '[{kernel,\n\t[\n\t\t{sync_nodes_optional, [\'';
  	var nodeList = [];
    var j = 0;

  	// Add list of other nodes to sync with from app
  	for (; j < smileysNodes.length ; ++j) {
  		if (j != i) {
  			nodeList.push(smileysNodes[j].name);
  		}
  	}

  	syncNodeConfig += nodeList.join('\', \'');

  	syncNodeConfig += '\']},\n\t\t{sync_nodes_timeout, 30000}\n\t]}\n].';

    var nodeConf = nodeConfs[smileysNodes[i].name]

    // write for app
  	fs.writeFile('gulp_output/' + nodeConf.name + '.config.' + i, syncNodeConfig, (err) => {
      if (err) throw err;

      console.log('gulp_output/' + nodeConf.name + '.config file saved');
    });
  }
});

gulp.task('build_app', function() {
  return gulp.src('mix.exs', {read: false})
    .pipe(shell([
      "sudo ./node_modules/brunch/bin/brunch b -p && sudo MIX_ENV=prod mix do phoenix.digest, release --env=prod"
    ]));
});

gulp.task('build_api', function() {
  return gulp.src('mix.exs', {read: false})
    .pipe(shell([
      "sudo MIX_ENV=prod mix do phoenix.digest, release --env=prod"
    ]));
});

gulp.task('send_app', ['sftp_vm_args', 'sftp_node_sync', 'sftp_smileys'], function() {
});

gulp.task('ping', function () {
  smileysNodes.forEach(function(server, i) {
	  return gulpSSH[i]
	    .exec(['uptime', 'ls -a', 'pwd'], {filePath: 'commands.' + i + '.log'})
	    .pipe(gulp.dest('gulp/logs'))
  });
});

gulp.task('unpack_app', function() {
	smileysNodes.forEach(function(server, i) {
    var nodeConf = nodeConfs[server.name]

		return gulpSSH[i]
		    .exec([
		    	'echo ' + server.name, 
		    	'cd ' + nodeConf.dir, 
		    	'tar -xzf ' + nodeConf.name + '.tar.gz'], 
		    	{filePath: 'commands.' + i + '.log'})
		    .pipe(gulp.dest('gulp/logs'));
	});
});

gulp.task('start_app', function() {
	smileysNodes.forEach(function(server, i) {
		return gulpSSH[i]
		    .exec([
		    	'echo ' + server.name, 
		    	'cd ' + smileysWeb.dir,
		    	'./bin/' + smileysWeb.name + ' start'], 
		    	{filePath: 'commands.' + i + '.log'})
		    .pipe(gulp.dest('gulp/logs'));
	});
});

gulp.task('restart_app', function() {
	smileysNodes.forEach(function(server, i) {
    var nodeConf = nodeConfs[server.name]

		return gulpSSH[i]
		    .exec([
		    	'echo ' + server.name, 
		    	'cd ' + nodeConf.dir, 
		    	'./bin/' + nodeConf.name + ' reboot'], 
		    	{filePath: 'commands.' + i + '.log'})
		    .pipe(gulp.dest('gulp/logs'));
	});
});

// run commands that start local web and api services
gulp.task('dev_servers', function(){
  return gulp.src('mix.exs', {read: false})
    .pipe(shell([
      'cd ./apps/smileysweb', 'sudo mix phx.server'
    ]));
});

gulp.task('create_node_confs', ['create_vm_args', 'create_node_sync_config'], function(){
	console.log("Preparing build files.");
});


gulp.task('default', [], function() {
  console.log("All Default Tasks Initiated. There weren't any. Ha Ha.");
});

function errorHandler (error) {
  console.log(error.toString());
  this.emit('end');
}