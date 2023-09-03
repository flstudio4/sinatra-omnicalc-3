require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
require "sinatra/cookies"

get("/") do
  "
  <h1>Welcome to your Sinatra App!</h1>
  <p>Define some routes in app.rb</p>
  "
end

get("/umbrella") do
  erb(:umbrella)
end

post("/process_umbrella") do
  @user_location = params.fetch("user_location")
  gmaps_key = ENV.fetch("GMAPS_KEY")
  gmaps_url = URI("https://maps.googleapis.com/maps/api/geocode/json?address=#{@user_location}&key=#{gmaps_key}")
  raw_gmaps_data = Net::HTTP.get(gmaps_url)
  parsed_gmaps_data = JSON.parse(raw_gmaps_data)
  results_array = parsed_gmaps_data.fetch("results")
  first_result_hash = results_array.at(0)
  geometry_hash = first_result_hash.fetch("geometry")
  location_hash = geometry_hash.fetch("location")
  @latitude = location_hash.fetch("lat")
  @longitude = location_hash.fetch("lng")

  pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
  pirate_weather_url = URI("https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{@latitude},#{@longitude}")
  raw_pirate_weather_data = Net::HTTP.get(pirate_weather_url)
  parsed_pirate_weather_data = JSON.parse(raw_pirate_weather_data)
  currently_hash = parsed_pirate_weather_data.fetch("currently")
  @current_temp = currently_hash.fetch("temperature")

  precip_probability = currently_hash.fetch("precipProbability")
  @summary = currently_hash.fetch("summary")
  @result = ""

  if precip_probability > 0.10
    @result = "You might want to take an umbrella!"
  else
    @result = "You probably won't need an umbrella."  
  end

  erb(:process_umbrella)
end

get("/chat") do
  
  erb(:chat)
end

post("/add_message_to_chat") do 

  @message = params.fetch("user_message")
  API_KEY = ENV.fetch("AI_API_KEY")
  request_headers_hash = {
  "Authorization" => "Bearer #{API_KEY}",
  "content-type" => "application/json"
}

request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "system",
      "content" => "You are a helpful assistant who talks like Shakespeare."
    },
    {
      "role" => "user",
      "content" => "#{@message}"
    }
  ]
}

request_body_json = JSON.generate(request_body_hash)

raw_response = HTTP.headers(request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => request_body_json
).to_s

parsed_response = JSON.parse(raw_response)
content = parsed_response.fetch("choices")
content2 = content[0].fetch("message")
@content3 = content2.fetch("content")

cookies.store(@message, @message)
cookies.store(@content3, @content3)

erb(:add_message)
redirect "/chat"
end

get("/message") do
  erb(:ai_message)
end

post("/clear_chat") do
  cookies.delete(:key)

  redirect "/chat" 
end

post("/process_single_message") do
  @message = params.fetch("the_message")
  API_KEY = ENV.fetch("AI_API_KEY")
  request_headers_hash = {
  "Authorization" => "Bearer #{API_KEY}",
  "content-type" => "application/json"
}

request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "system",
      "content" => "You are a helpful assistant who talks like Shakespeare."
    },
    {
      "role" => "user",
      "content" => "#{@message}"
    }
  ]
}

request_body_json = JSON.generate(request_body_hash)

raw_response = HTTP.headers(request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => request_body_json
).to_s

parsed_response = JSON.parse(raw_response)
content = parsed_response.fetch("choices")
content2 = content[0].fetch("message")
@content3 = content2.fetch("content")
  erb(:process_single_message)
end
