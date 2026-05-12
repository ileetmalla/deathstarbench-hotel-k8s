request = function()
  local path = "/hotels?inDate=2015-04-09&outDate=2015-04-10&lat=37.7749&lon=-122.4194"
  return wrk.format("GET", path, {}, nil)
end
