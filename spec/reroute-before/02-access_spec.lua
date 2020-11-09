local helpers = require "spec.helpers"
local cjson    = require "cjson"

local PLUGIN_NAME = "reroute-before"

for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
          before = {
            {
              header_name = "X-Tenants",
              header_value = "senior",
              url = "http://mockbin.com/request?foo=bar&foo=baz"
            }
          },
          timeout = 10000,
          run_on_preflight = false
        }
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)



    describe("request without plugin", function()
      it("gets a 'X-Tenant' header", function()
        local r = client:get("/request", {
          headers = {
            host = "test1.com",
            ["X-Tenant"] = "senior"
          }
        })
        -- validate that the request succeeded, response status 200
        local body_value =assert.response(r).has.status(200)
        -- now check the request (as echoed by mockbin) to have the header
        local header_value = assert.request(r).has.header("X-Tenant")
        -- validate the value of that header
        assert.equal("senior", header_value)

        assert.equal("senior", cjson.decode(body_value).headers["x-tenant"])
      end)
    end)



    -- describe("response", function()
    --   it("gets a 'bye-world' header", function()
    --     local r = client:get("/request", {
    --       headers = {
    --         host = "test1.com"
    --       }
    --     })
    --     -- validate that the request succeeded, response status 200
    --     assert.response(r).has.status(200)
    --     -- now check the response to have the header
    --     local header_value = assert.response(r).has.header("bye-world")
    --     -- validate the value of that header
    --     assert.equal("this is on the response", header_value)
    --   end)
    -- end)

  end)
end
