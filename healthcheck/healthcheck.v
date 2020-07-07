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

import os
import net.http

// call the given HTTP health check route
// to minimize its dimension, ensure to compile with all optimizations (for production) ...

fn main() {
	mut url := 'http://localhost:8000/health' // default URL for health check
	if os.args.len > 1 {
		url = os.args[1]
	}
	println("GET call for healthcheck at: ${url} ...")

	resp := http.get(url) or {
		println(err)
		exit(1)
	}
	println(resp.text)

	if resp.status_code != 200 {
		exit(resp.status_code)
	}

}
