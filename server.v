/*
 * Copyright 2020 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module main

import log
import time
import v.util as vu
import v.vmod
import vweb

// expose a simple, minimal web server
// to use it for simple benchmarks, ensure to compile with all optimizations (for production) ...
// note that at the moment there is no reload of resources when the server is started ... later check if/how to achieve it ...

const (
	// server          = 'localhost'
	port            = 8000
	v_version       = vu.v_version
	log_level       = log.Level.info // set to .debug for more logging
	// log_file        = './logs/server.log'
)

struct App {
mut:
	log       log.Log = log.Log{} // integrated logging
	metadata  vmod.Manifest // some metadata; later check if use a Map instead ...
	// html_path vweb.RawHtml
pub mut:
    vweb      vweb.Context
	cnt       int // sample, to count number of page requests
	logged_in bool // sample, tell if user is logged in
	// user      User
}

// set application configuration
fn (mut app App) set_app_config() {
	// instance and configures logging, etc
	app.log.set_level(log_level)
	// app.log.set_full_logpath(log_file)
	app.log.info('Logging level set to ${log_level}')
}

// set application metadata from application module
fn (mut app App) set_app_metadata() {
	// get metadata from application module at build time and set in in application
	app.metadata = vmod.decode( @VMOD_FILE ) or {
		app.log.fatal('unable to fing V module file')
		panic(err)
	}
	// add some extra data, like: built-with/V version, etc
	app.metadata.unknown['v-version'] << v_version
	app.metadata.unknown['framework'] << 'vweb'
	$if debug {
		app.log.info('application metadata (from module): ${app.metadata}')
	}
}

// set application mappings for static content(assets, etc)
fn (mut app App) set_app_static_mappings() {
	app.vweb.serve_static('/favicon.ico', 'public/img/favicon.ico', 'image/x-icon')
	// publish static content from a specific folder
	// app.vweb.handle_static('.') // serve static content from current folder
	// app.vweb.handle_static('public') // serve static content from folder './public'
	// but note that it doesn't work with templates ...
	// so add an explicit reference to css ...
	app.vweb.serve_static('/css/style.css', 'public/css/style.css', 'text/css')
	// later disable previous mapping for css and check if/how to serve it as a generic static content ...
	// note that template files now can be in the same folder, or under 'templates/' ...
	app.vweb.serve_static('/img/GitHub-Mark-Light-32px.png', 'public/img/GitHub-Mark-Light-32px.png', 'image/png')
}

// entry point og the application
fn main() {
	// println("Server listening on 'http://${server}:${port}' ...")
    vweb.run<App>(port)
}

// initialization of webapp
pub fn (mut app App) init_once() {
	app.log.info("Application initialization ...")
	// config application
	app.set_app_config()

	// set application metadata
	app.set_app_metadata()

	// map static content (assets, etc)
	app.set_app_static_mappings()

	// initialization done
	app.log.info('${app.metadata.name}-${app.metadata.version} initialized')
	app.log.info('vweb appl, built with V ${v_version}') // print V version (set at build time)
}

// initialization before any action
pub fn (mut app App) init() {
	// url := app.vweb.req.url
	// app.log.debug('${@FN}: url=$url')
	app.log.debug('${@FN}: total number of page requested (but not other content)=$app.cnt')
	// app.logged_in = app.logged_in()
}

// redirect to home page
pub fn (mut app App) to_home() vweb.Result {
	return app.vweb.redirect('/')
}

// serve some content on the root (index) route '/'
// note that this requires template page 'index.html', or compile will fail ...
pub fn (mut app App) index() vweb.Result {
	app.cnt++ // sample, increment count number of page requests
	// many variables, like V version (set at build time) are automatically injected into template files
    return $vweb.html()
}

// sample health check route that exposes a fixed json reply at '/health'
pub fn (mut app App) health() vweb.Result {
	return app.vweb.json('{"statusCode":200, "status":"ok"}')
}

// sample readiness route that exposes a fixed json reply at '/ready'
pub fn (mut app App) ready() vweb.Result {
	// wait for some seconds here, to simulate a real dependencies check (and a slow reply) ...
	time.sleep(10) // wait for 10 seconds
	return app.vweb.json('{"statusCode":200, "status":"ok", 
		"msg":"Dependencies ok, ready to accept incoming traffic now"}
	')
}

pub fn (mut app App) headerfooter() vweb.Result {
	app.cnt++ // sample, increment count number of page requests
    return $vweb.html() // sample template page with hardcoded support for header and footer ...
}

/*
// TODO: enable when include in templates will be fully working ... wip
// serve a template with nested includes on the route '/includes'
// note that this requires template page 'index.html', or compile will fail ...
pub fn (mut app App) includes() vweb.Result {
	app.cnt++ // sample, increment count number of page requests
    return $vweb.html() // sample template page with includes ...
}
 */

// sample route that exposes a text reply at '/cookie'
// show headers in the reply (as text), and set a sample cookie
pub fn (mut app App) cookie() vweb.Result {
	app.vweb.set_cookie(name:'cookie', value:'test')
	return app.vweb.text('Headers: $app.vweb.headers')
}

// sample route that exposes a text reply at '/hello'
pub fn (mut app App) hello() vweb.Result {
	return app.vweb.text('Hello world from vweb at ${time.now().format_ss()}')
}

// sample route that exposes a json reply at '/hj'
pub fn (mut app App) hj() vweb.Result {
	return app.vweb.json('{"Hello":"World"}')
}

// sample route that exposes a json reply at '/time'
pub fn (mut app App) time() vweb.Result {
	now := time.now()
	return app.vweb.json('{"timestamp":"${now.unix_time()}", "time":"$now"}')
}

// sample route with a not existent path, that exposes a fixed json reply at '/not/existent'
// expected an HTTP error 404 (not found)
pub fn (mut app App) not_existent() vweb.Result {
	return app.vweb.json('{"msg":"Should not see this reply"}')
}

// sample route with nested path, that exposes a fixed json reply at '/user/:id' and '/user/:id/info'
// ['/user/:id'] // commented to avoid compiler warning on method arguments mismatch ...
['/user/:id/info']
pub fn (mut app App) user_info(user string) vweb.Result {
	return app.vweb.json('{"msg":"Hi, it\'s me (user: $user)"}')
}

// sample route with an application selected HTTP status code, that exposes a fixed json reply at '/mystatus'
// (the given code must be a valid code, in the range 100..599)
pub fn (mut app App) mystatus() vweb.Result {
	app.vweb.set_status(406, 'My error description') // 406 Not Acceptable, as a sample I change here its description in the reply
	return app.vweb.json('{"msg":"My HTTP status code and message"}')
}

// sample route with application info (metadata), with a reply at '/info'
['/info']
pub fn (mut app App) app_info() vweb.Result {
	return app.vweb.text(app.metadata.str())
}

