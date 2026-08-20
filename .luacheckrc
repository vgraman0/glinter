std = "lua54"
exclude_files = { "lua_modules" }
files["spec"] = {
  std = "+busted",
}
files["spec/cli_spec.lua"] = {
  std = "+busted",
  ignore = { "122" },
}
