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

import time
import v.util as vu
import vweb

// expose a simple, minimal web server
// to use it for simple benchmarks, ensure to compile with all optimizations (for production) ...
// note that at the moment there is no reload of resources when the server is started ... later check if/how to achieve it ...
// later check how to disable vweb write page requests to console log ...
// later check if/how to bind to a specific network interface (like '0.0.0.0'), to be able to expose even whrn running in a container for example ...

const (
	// server = 'localhost'
	port = 8000
	v_version = vu.v_version
)

struct App {
pub mut:
    vweb vweb.Context
	cnt  int // sample, to count number of page requests
}

fn main() {
	// println("Server listening on 'http://${server}:${port}' ...")
    vweb.run<App>(port)
}

// initialization of webapp
pub fn (mut app App) init_once() {
	app.vweb.serve_static('/favicon.ico', './public/img/favicon.ico', 'image/x-icon')
	// publish static content from a specific folder
	// app.vweb.handle_static('.') // serve static content from current folder
	// app.vweb.handle_static('public') // serve static content from folder './public'
	// but note that it doesn't work with templates ...
	// so add an explicit reference to css ...
	app.vweb.serve_static('/css/style.css', './public/css/style.css', 'text/css')
	// later disable previous mapping for css and check if/how to serve it as a generic static content ...
	// note that template files now can be in the same folder, or under 'templates/' ...
	println('vweb appl, built with V ${v_version}') // print V version (used at build time)
}

// initialization before any action
pub fn (mut app App) init() {
}

// serve some content on the root (index) route '/'
// note that this requires template page 'index.html', or compile will fail ...
pub fn (mut app App) index() vweb.Result {
	app.cnt++ // sample, increment count number of page requests
	// inject V version (used at build time) into template used here
	// println('vweb appl, built with V ${v_version}') // print V version (used at build time)
    return $vweb.html()
}

// sample health check route that exposes a fixed json reply at '/health'
pub fn (mut app App) health() vweb.Result {
	return app.vweb.json('{"statusCode":200, "status":"ok"}')
}

// sample readiness route that exposes a fixed json reply at '/ready'
pub fn (mut app App) ready() vweb.Result {
	// later add a wait for some seconds here, to simulate dependencies check ...
	return app.vweb.json('{"statusCode":200, "status":"ok", 
		"msg":"Dependencies ok, ready to accept incoming traffic now"}
	')
}

pub fn (mut app App) headerfooter() vweb.Result {
    return $vweb.html() // sample template page with hardcoded support for header and footer ...
}

/*
// TODO: enable when include in templates will be fully working ... wip
// serve a template with nested includes on the route '/includes'
// note that this requires template page 'index.html', or compile will fail ...
pub fn (mut app App) includes() vweb.Result {
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
	return app.vweb.text('Hello world from vweb at ${time.now().format()}')
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

// sample route with nested path, that exposes a fixed json reply at '/user/:id'
// later check if this route mapping is good, and how to read the given id ...
pub fn (mut app App) user_id() vweb.Result {
	return app.vweb.json('{"msg":"Hi, it\'s me"}')
}
