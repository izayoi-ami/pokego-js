Discord = require("discord.js")
Repeat = require("repeat")
request = require("request-json")
buildUrl = require("build-url")
flatten=require("flatten")
jsonfile = require('jsonfile')

config_file = "./config/config.json"
config = jsonfile.readFileSync(config_file)

token= config.token 
bot = new Discord.Client(disableEveryone: false)

skiplag_url = "http://skiplagged.com/api/pokemon.php"
global = exports ? this
cid = global.cid = config.cid
lid = global.lid = config.lid
global.bounds=[
  {bounds: "22.179639,113.823194,22.561978,114.412522"}
  {bounds: "37.685671,-122.839237,38.073721,-121.523624"}
  {bounds: "49.578913,2.811516,52.503081,8.211296"}
]
global.addresses=[
  {address:"London"}
  {address:"Paris"}
  {address:"Texas"}
  {address:"New York"}
]
global.snipe_ids=[].concat(
  [1..9],
  [33,58],
  [133 .. 149]
)
global.cnt = 0
start="==================START======================\n"
end  ="==================END========================\n"

work = () ->
  client = []
  body = []
  res = []
  err = []
  a = global.bounds.length
  b = global.addresses.length
  n = global.cnt
  global.cnt = (n + 1) % (a*b)
  console.log "Scanning..."
  params =[ global.bounds[n%a], global.addresses[n%b] ]
  console.log params
  await
    for param,i in params
      client[i] = request.createClient skiplag_url
      url=buildUrl(skiplag_url, queryParams: param)
      client[i].get buildUrl(skiplag_url, queryParams: param), defer err[i],res[i],body[i]
      console.log "Query: #{url}"
  poke = []
  poke = ( b.pokemons for b,i in body when not err[i]?)
  if poke.length > 0
    console.log "Processing Data"
    poke = ( x.filter((t)->t.pokemon_id in global.snipe_ids) for x in poke when x )
    #poke = poke.map((x)->x.filter?((t)->t.pokemon_id in global.snipe_ids))
    ps = flatten(poke)
    ps = ( "#{p.latitude},#{p.longitude} #{p.pokemon_name}" for p in ps)
    s = ps.join "\n"
    bot.sendMessage(cid, start+ s + "\n" +end)
    console.log s
    console.log "Result sent"
  else
    console.log "No Data Received. Possible errors are shown:"
    for e in err
      console.log e
    bot.sendMessage(lid,"Urgent. Error Occur. Please check server log.", disableEveryone: false)

bot.on "ready", ()->
  bot.sendMessage(lid,"Hi, I logged in.", disableEveryone:false)
  Repeat(work).every(45, 's').start()

###
bot.on("message", (msg) => {

	if (msg.content === "photos") {
   
    console.log(msg.channel)
    bot.sendMessage("209269038415740929","HelloWorld")
    bot.sendMessage(msg.channel, "Hello")
    bot.sendFile(msg, "./test/image.png", "photo.png", (err, sentMessage) => {
			if (err)
				console.log("Couldn't send image: ", err)
		})
	}

	else if (msg.content === "file") {
    bot.sendFile(msg.channel, new Buffer("Text in a file!"), "file.txt", (err, sentMessage) => {
			if (err)
				console.log("Couldn't send file: ", err)
		})
	}
})
###
bot.loginWithToken(token)
