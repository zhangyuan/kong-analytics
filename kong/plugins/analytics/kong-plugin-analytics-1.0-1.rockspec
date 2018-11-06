package = "kong-plugin-analytics"
version = "1.0-1"

description = {
  summary = "A Kong plugin.",
}

source = {
  url = "...",
}

dependencies = {
  "lua ~> 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.analytics.handler"] = "kong/plugins/analytics/handler.lua",
    ["kong.plugins.analytics.schema"] = "kong/plugins/analytics/schema.lua",
  }
}