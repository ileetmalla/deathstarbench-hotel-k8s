request = function()
  local path = "/user?username=Cornell_1&password=1111111111"
  return wrk.format("POST", path, {}, nil)
end
