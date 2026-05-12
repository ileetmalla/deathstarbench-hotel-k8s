request = function()
  local path = "/recommendations?require=dis&lat=37.7749&lon=-122.4194"
  return wrk.format("GET", path, {}, nil)
end
