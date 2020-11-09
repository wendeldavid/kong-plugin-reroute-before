[![Build Status][badge-travis-image]][badge-travis-url]

Kong plugin template
====================

This repository contains a very simple Kong plugin template to get you
up and running quickly for developing your own plugins.

This template was designed to work with the
[`kong-pongo`](https://github.com/Kong/kong-pongo) and
[`kong-vagrant`](https://github.com/Kong/kong-vagrant) development environments.

Please check out those repos `README` files for usage instructions.

[badge-travis-url]: https://travis-ci.org/Kong/kong-plugin/branches
[badge-travis-image]: https://travis-ci.com/Kong/kong-plugin.svg?branch=master

```json
{
	"config": {
		"around": [
			{
				"header_name": "X-Tenant",
				"header_value": "senior", 
				"url": "http://nodezera:8080/bridge/rest/endpoint_2"
			}
		], 
		"timeout": 10000, 
		"run_on_preflight": false
	},
	"name":"reroute-around"
}
```