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

import vweb

// expose a simple, minimal web server
// to use it for simple benchmarks, ensure to compile with all optimizations (for production) ...

const (
	// server = 'localhost'
	port = 8000
)

struct App {
pub mut:
    vweb vweb.Context
}

fn main() {
	// println("Server listening on 'http://${server}:${port}' ...")
    vweb.run<App>(port)
}

// initialization of webapp
pub fn (mut app App) init_once() {
	// app.vweb.handle_static('.') // serve static content from current folder
	// app.vweb.handle_static('public') // serve static content from folder './public'
	// note that template files now can be in the same folder, or under 'templates/' ...
}

// initialization before any action
pub fn (mut app App) init() {
}

// serve some content on the root (index) route '/'
// note that this implementation doesn't requires a template page ...
pub fn (mut app App) index() vweb.Result {
	return app.vweb.json('{"hello": "world"}')
}

