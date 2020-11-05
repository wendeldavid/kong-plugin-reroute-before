local inspect = require('inspect')

local PLUGIN_NAME = "reroute-before"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

describe(PLUGIN_NAME .. ": (schema)", function()


  -- it("accepts distinct request_header and response_header", function()
  --   local ok, err = validate({
  --       request_header = "My-Request-Header",
  --       response_header = "Your-Response",
  --     })
  --   assert.is_nil(err)
  --   assert.is_truthy(ok)
  -- end)


  -- it("does not accept identical request_header and response_header", function()
  --   local ok, err = validate({
  --       request_header = "they-are-the-same",
  --       response_header = "they-are-the-same",
  --     })

  --   assert.is_same({
  --     ["config"] = {
  --       ["@entity"] = {
  --         [1] = "values of these fields must be distinct: 'request_header', 'response_header'"
  --       }
  --     }
  --   }, err)
  --   assert.is_falsy(ok)
  -- end)

  it("test configuration with 1 custom route", function()
    local ok, err = validate({
        before = {
        {
          header_name = "X-Tenant",
          header_value = "senior", 
          url = "http://nodezera:8080/bridge/rest/endpoint_1"
        }
      },
      timeout = 10000,
      run_on_preflight = false
    })

    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("test configuration with 2 custom routes", function()
    local ok, err = validate({
        before = {
        {
          header_name = "X-Tenant",
          header_value = "senior", 
          url = "http://nodezera:8080/bridge/rest/endpoint_1"
        },
        {
          header_name = "X-Tenant",
          header_value = "senior", 
          url = "http://nodezera:8080/bridge/rest/endpoint_2"
        }
      },
      timeout = 10000,
      run_on_preflight = false
    })

    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("test configuration with required field missing -> header_name", function()
    local ok, err = validate({
        before = {
        {
          header_value = "senior",
          url = "http://nodezera:8080/bridge/rest/endpoint_1"
        }
      },
      timeout = 10000,
      run_on_preflight = false
    })

    assert.is_truthy(err)
    assert.is_nil(ok)

    assert.is_same({
      ["config"] = {
        ["before"] = {
          [1] = {
            ["header_name"] = "required field missing"
          }
        }
      }
    }, err)
  
  end)

  it("test configuration with required field missing -> header_value", function()
    local ok, err = validate({
        before = {
        {
          header_name = "X-Tenant",
          url = "http://nodezera:8080/bridge/rest/endpoint_1"
        }
      },
      timeout = 10000,
      run_on_preflight = false
    })

    assert.is_truthy(err)
    assert.is_nil(ok)

    assert.is_same({
      ["config"] = {
        ["before"] = {
          [1] = {
            ["header_value"] = "required field missing"
          }
        }
      }
    }, err)
  
  end)

  it("test configuration with required field missing -> url", function()
    local ok, err = validate({
        before = {
        {
          header_name = "X-Tenant",
          header_value = "senior"
        }
      },
      timeout = 10000,
      run_on_preflight = false
    })

    assert.is_truthy(err)
    assert.is_nil(ok)

    assert.is_same({
      ["config"] = {
        ["before"] = {
          [1] = {
            ["url"] = "required field missing"
          }
        }
      }
    }, err)
  
  end)
  

end)
