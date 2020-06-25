module main

import time
import vweb

// expose a simple, minimal web server
// to use it for simple benchmarks, ensure to compile with all optimizations (for production) ...
// note that at the moment there is no reload of resources when the server is started ... later check if/how to achieve it ...
// later check how to disable vweb write page requests to console log ...
// later check if/how to bind to a specific network interface (like '0.0.0.0'), to be able to expose even whrn running in a container for example ...

const (
	// server = 'localhost'
	port = 8000
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
}

// initialization before any action
pub fn (mut app App) init() {
}

// serve some content on the root (index) route '/'
// note that this requires template page 'index.html', or compile will fail ...
fn (mut app App) index() vweb.Result  {
	app.cnt++ // sample, increment count number of page requests
    return $vweb.html()
}

fn (mut app App) header_footer() vweb.Result {
    return $vweb.html() // sample template page with hardcoded support for header and footer ...
}

/*
// TODO: enable when include in templates will be fully working ... wip
// serve a template with nested includes on the route '/includes'
// note that this requires template page 'index.html', or compile will fail ...
fn (mut app App) includes() vweb.Result {
    return $vweb.html() // sample template page with includes ...
}
 */

// sample route that exposes a text reply at '/cookie'
// show headers in the reply (as text), and set a sample cookie
pub fn (mut app App) cookie() {
	app.vweb.set_cookie('cookie', 'test')
	app.vweb.text('Headers: $app.vweb.headers')
}

// sample route that exposes a text reply at '/hello'
pub fn (mut app App) hello() {
	app.vweb.text('Hello world from vweb at ${time.now().format()}')
}

// sample route that exposes a json reply at '/time'
pub fn (mut app App) time() {
	now := time.now()
	app.vweb.json('{"timestamp": "${now.unix_time()}", "time":"$now"}')
}
