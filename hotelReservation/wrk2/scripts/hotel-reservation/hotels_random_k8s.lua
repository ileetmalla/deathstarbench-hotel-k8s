math.randomseed(os.time())
math.random()
math.random()
math.random()

local function date_str(day)
  if day <= 9 then
    return "2015-04-0" .. tostring(day)
  end
  return "2015-04-" .. tostring(day)
end

request = function()
  local in_day = math.random(9, 23)
  local out_day = math.random(in_day + 1, 24)

  local lat = 38.0235 + (math.random(0, 481) - 240.5) / 1000.0
  local lon = -122.095 + (math.random(0, 325) - 157.0) / 1000.0

  local path = "/hotels?inDate=" .. date_str(in_day) ..
               "&outDate=" .. date_str(out_day) ..
               "&lat=" .. tostring(lat) ..
               "&lon=" .. tostring(lon)

  return wrk.format("GET", path, {}, nil)
end
