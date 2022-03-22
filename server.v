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
// import os
import time
import v.util.version as vuv
import v.vmod
import vweb

// expose a simple, minimal web server
// to use it for simple benchmarks, ensure to compile with all optimizations (for production) ...
// note that at the moment there is no reload of resources when the server is started ... later check if/how to achieve it ...

const (
	// server    = 'localhost'
	port      = 8000
	timeout   = 10 * time.second // default is in msec (if not multiplied)
	v_version = vuv.v_version
	// v_version = vuv.full_v_version(false)
	// log_file  = './logs/server.log'
)

struct App {
	vweb.Context
	port       int // http port
	timeout    i64 // shutdown timeout
	started_at u64 // start timestamp
mut:
	state     shared State   // app shared state
	log       shared log.Log // integrated logging
	log_level log.Level      // logging level
pub mut:
	// db        sqlite.DB
	logged_in bool // sample, tell if user is logged in
	user_id   string
	// user      User
}

struct State {
mut:
	cnt_page int // sample, to count total number of page requests
	cnt_api  int // sample, to count total number of api requests
	metadata map[string]string // some metadata
}

// set_app_config set application configuration
fn (mut app App) set_app_config() {
	// instance and configures logging: minimum logging level, etc
	$if debug {
		app.log_level = log.Level.debug
	} $else {
		app.log_level = log.Level.info
	}
	lock app.log {
		app.log.set_level(app.log_level)
	}
	println('Logging level set to $app.log_level')

	// app.log.set_full_logpath(log_file)
}

// set_app_metadata set application metadata from application module
fn (mut app App) set_app_metadata() {
	// get metadata from application module at build time and set in in application
	// or terminate execution
	manifest := vmod.decode(@VMOD_FILE) or {
		lock app.log {
			app.log.fatal('unable to read V module file')
		}
		panic(err) // already called by logger fatal method, but needed by the compiler at the moment
	}
	lock app.state {
		app.state.metadata = {
			// add some data from the manifest
			'name':        manifest.name
			'version':     manifest.version
			'description': manifest.description
			// add some extra data, like: built-with/V version, etc
			'v-version':   v_version
			'framework':   'vweb'
		}
	}
	$if debug {
		rlock app.state {
			app.log_info('application metadata (from module): $app.state.metadata')
		}
	}
}

// set_app_static_mappings set application mappings for static content(assets, etc)
fn (mut app App) set_app_static_mappings() {
	// map some static content
	// but first change to executable folder
	// os.chdir(os.dir(os.executable())) ?
	// app.handle_static('.', false) // serve static content from current folder
	app.serve_static('/favicon.ico', 'public/img/favicon.ico')
	app.serve_static('/css/style.css', 'public/css/style.css')
	app.serve_static('/img/GitHub-logo.png', 'public/img/GitHub-Mark-Light-32px.png')
	// publish static content from a specific folder
	// app.mount_static_folder_at(os.resource_abs_path('./public/img'), '/img')
	// later disable previous mapping for css and check if/how to serve it as a generic static content ...
	// note that template files now can be in the same folder, or under 'templates/' ...
}

// main entry point of the application
fn main() {
	// println("Server listening on 'http://${server}:${port}' ...")
	vweb.run(new_app(), port)
}

// new_app creates and returns a new app instance
fn new_app() &App {
	mut app := &App{
		port: port
		timeout: timeout
		started_at: u64(time.now().unix)
	}

	// additional app instance startup only configuration
	println('Server initialization at ${app.started_at}...')
	// config application
	app.set_app_config()
	app.log_info('Application initialization ...') // after set logger level

	// set application metadata
	app.set_app_metadata()

	// map static content (assets, etc)
	app.set_app_static_mappings()

	// initialization done
	rlock app.state {
		app.log_info('${app.state.metadata['name']}-${app.state.metadata['version']} initialized')
	}
	app.log_info('vweb appl, built with V $v_version') // print V version (set at build time)

	$if debug {
		app.log_info('V compile time debug flag enabled') // print V compile time debug flag, when enabled
	}

	return app
}

// before_request initialization just before any route call
pub fn (mut app App) before_request() {
	// url := app.req.url
	// app.log_debug('${@FN}: url=$url')
	// app.log_debug('debug test') // temp
	$if debug { // small optimization, but in general needed only in performance critical parts ...
		rlock app.state {
			msg := '${@FN}: requested total pages: $app.state.cnt_page, total api: $app.state.cnt_api'
			// println(msg) // no more needed now
			app.log_debug(msg)
		}
	}
	// app.logged_in = app.logged_in()
	app.user_id = app.get_cookie('id') or { '0' }
}

// log_debug log with verbosity debug, using application logger
fn (mut app App) log_debug(msg string) {
	lock app.log {
		app.log.debug(msg)
	}
}

// log_info log with verbosity info, using application logger
fn (mut app App) log_info(msg string) {
	lock app.log {
		app.log.info(msg)
	}
}

// inc_cnt_page increment and return counter value for page calls, from shared state
fn (mut app App) inc_cnt_page() int {
	mut data := lock app.state {
		app.state.cnt_page++
	}
	return data
}

// inc_cnt_api increment and return counter value for api calls, from shared state
fn (mut app App) inc_cnt_api() int {
	mut data := lock app.state {
		app.state.cnt_api++
	}
	return data
}

// app_name return app name, from shared state
fn (mut app App) app_name() string {
	mut data := rlock app.state {
		app.state.metadata['name']
	}
	return data
}

// app_version return app name, from shared state
fn (mut app App) app_version() string {
	mut data := rlock app.state {
		app.state.metadata['version']
	}
	return data
}

/*
// graceful_exit logic for graceful shutdown of the webapp
// future use
fn (mut app App) graceful_exit() {
	app.log_info("Application shutdown in $app.timeout msec ...")
	time.sleep_ms(app.timeout)
	exit(0)
}
*/

// to_home redirect to home page
pub fn (mut app App) to_home() vweb.Result {
	return app.redirect('/')
}

// index serve some content on the root (index) route '/'
// note that this requires template page 'index.html', or compile will fail ...
pub fn (mut app App) index() vweb.Result {
	app.inc_cnt_page() // sample, increment count number of page requests
	// many variables, like V version (set at build time) are automatically injected into template files
	return $vweb.html()
}

// health sample health check route that exposes a fixed json reply at '/health'
pub fn (mut app App) health() vweb.Result {
	app.inc_cnt_api() // sample, increment count number of api requests
	app.log_info(@FN) // sample, to ensure log calls from routes works
	return app.json('{"statusCode":200, "status":"ok"}')
	// same as:
	// app.json('{"statusCode":200, "status":"ok"}')
	// return vweb.Result{}
}

// ready sample readiness route that exposes a fixed json reply at '/ready'
pub fn (mut app App) ready() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	// wait for some seconds here, to simulate a real dependencies check (and a slow reply) ...
	time.sleep(5 * time.second) // wait for 5 seconds
	return app.json('{"statusCode":200, "status":"ok", 
		"msg":"Dependencies ok, ready to accept incoming traffic now"}
	')
}

// headerfooter sample route to serve a template page with includes
pub fn (mut app App) headerfooter() vweb.Result {
	app.inc_cnt_page()
	return $vweb.html() // sample template page with hardcoded support for header and footer ...
}

// includes serve a template with nested includes on the route '/includes'
// note that this requires template page 'index.html', or compile will fail ...
pub fn (mut app App) includes() vweb.Result {
	app.inc_cnt_page()
	return $vweb.html() // sample template page with includes ...
}

// cookie sample route that exposes a text reply at '/cookie'
// show headers in the reply (as text), and set a sample cookie
pub fn (mut app App) cookie() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	app.set_cookie(name: 'cookie', value: 'test')
	return app.text('Headers: TODO') // $app.headers')
}

// hello sample route that exposes a text reply at '/hello'
pub fn (mut app App) hello() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	return app.text('Hello world from vweb at $time.now().format_ss()')
}

// hj sample route that exposes a json reply at '/hj'
pub fn (mut app App) hj() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	return app.json('{"Hello":"World"}')
}

// time sample route that exposes a json reply at '/time'
pub fn (mut app App) time() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	now := time.now()
	return app.json('{"timestamp":"$now.unix_time()", "time":"$now"}')
}

// not_existent sample route with a not existent path, that exposes a fixed json reply at '/not/existent'
// expected an HTTP error 404 (not found)
pub fn (mut app App) not_existent() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	return app.json('{"msg":"Should not see this reply"}')
}

// user_info sample route with nested path, that exposes a fixed json reply at '/user/:id' and '/user/:id/info'
// ['/user/:id'] // commented to avoid compiler warning on method arguments mismatch ...
['/user/:id/info']
pub fn (mut app App) user_info(user string) vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	return app.json('{"msg":"Hi, it\'s me (user: $user)"}')
}

// mystatus sample route with an application selected HTTP status code, that exposes a fixed json reply at '/mystatus'
// (the given code must be a valid code, in the range 100..599)
pub fn (mut app App) mystatus() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	app.set_status(406, 'My error description') // 406 Not Acceptable, as a sample I change here its description in the reply
	return app.json('{"msg":"My HTTP status code and message"}')
}

// app_info sample route with application info (metadata), with a reply at '/info'
['/info']
pub fn (mut app App) app_info() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	// return app.text(app.metadata.str())
	mut metadata := ''
	rlock app.state {
		// println('$app.state.metadata') // temp
		// check later how to have this work ...
		// app.log_debug('${app.state.metadata['name']}-${app.state.metadata['version']} initialized')
		metadata = '$app.state.metadata'
	}
	app.log_debug(@FN)
	return app.text(metadata)
}

// post sample route to dump the given data (via HTTP POST)
[post]
pub fn (mut app App) post_dump() vweb.Result {
	app.inc_cnt_api()
	app.log_info(@FN)
	return app.text('Post body: $app.req.data')
}
