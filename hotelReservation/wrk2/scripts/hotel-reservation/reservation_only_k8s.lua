request = function()
  local path = "/reservation?inDate=2015-04-09&outDate=2015-04-10&lat=37.7749&lon=-122.4194&hotelId=1&customerName=Cornell_1&username=Cornell_1&password=1111111111&number=1"
  return wrk.format("POST", path, {}, nil)
end
