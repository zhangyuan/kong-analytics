return {
  no_consumer = false,
  fields = {
    host = { required = true, type = "string", required = true },
    port = { required = true, type = "number", required = true },
    timeout = { default = 10000, type = "number", required = true },
    tag = { required = true, type = "string", required = true, default = "kong" },
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    return true
  end
}