math.randomseed(os.time())
math.random()
math.random()
math.random()

local function get_user()
  local id = math.random(0, 500)
  local user_name = "Cornell_" .. tostring(id)

  local pass_word = ""
  for i = 0, 9, 1 do
    pass_word = pass_word .. tostring(id)
  end

  return user_name, pass_word
end

local function date_str(day)
  if day <= 9 then
    return "2015-04-0" .. tostring(day)
  end
  return "2015-04-" .. tostring(day)
end

local function random_location()
  local lat = 38.0235 + (math.random(0, 481) - 240.5) / 1000.0
  local lon = -122.095 + (math.random(0, 325) - 157.0) / 1000.0
  return lat, lon
end

local function search_hotel()
  local in_day = math.random(9, 23)
  local out_day = math.random(in_day + 1, 24)

  local in_date = date_str(in_day)
  local out_date = date_str(out_day)
  local lat, lon = random_location()

  local path = "/hotels?inDate=" .. in_date ..
               "&outDate=" .. out_date ..
               "&lat=" .. tostring(lat) ..
               "&lon=" .. tostring(lon)

  return wrk.format("GET", path, {}, nil)
end

local function recommend()
  local coin = math.random()
  local req_param = ""

  if coin < 0.33 then
    req_param = "dis"
  elseif coin < 0.66 then
    req_param = "rate"
  else
    req_param = "price"
  end

  local lat, lon = random_location()

  local path = "/recommendations?require=" .. req_param ..
               "&lat=" .. tostring(lat) ..
               "&lon=" .. tostring(lon)

  return wrk.format("GET", path, {}, nil)
end

local function reserve()
  local in_day = math.random(9, 23)
  local out_day = in_day + math.random(1, 5)

  local in_date = date_str(in_day)
  local out_date = date_str(out_day)
  local lat, lon = random_location()

  local hotel_id = tostring(math.random(1, 80))
  local user_id, password = get_user()
  local cust_name = user_id
  local num_room = "1"

  local path = "/reservation?inDate=" .. in_date ..
               "&outDate=" .. out_date ..
               "&lat=" .. tostring(lat) ..
               "&lon=" .. tostring(lon) ..
               "&hotelId=" .. hotel_id ..
               "&customerName=" .. cust_name ..
               "&username=" .. user_id ..
               "&password=" .. password ..
               "&number=" .. num_room

  return wrk.format("POST", path, {}, nil)
end

local function user_login()
  local user_name, password = get_user()

  local path = "/user?username=" .. user_name ..
               "&password=" .. password

  return wrk.format("POST", path, {}, nil)
end

request = function()
  local search_ratio = 0.60
  local recommend_ratio = 0.39
  local user_ratio = 0.005

  local coin = math.random()

  if coin < search_ratio then
    return search_hotel()
  elseif coin < search_ratio + recommend_ratio then
    return recommend()
  elseif coin < search_ratio + recommend_ratio + user_ratio then
    return user_login()
  else
    return reserve()
  end
end
