Discord = require("discord.js")
Repeat = require("repeat")
request = require("request-json")
buildUrl = require("build-url")
flatten=require("flatten")
jsonfile = require('jsonfile')
MultiRange = require("multi-integer-range").MultiRange

config_file = "./config/config.json"
config = jsonfile.readFileSync(config_file)

bot = new Discord.Client(disableEveryone: false)

skiplag_url = "http://skiplagged.com/api/pokemon.php"
global = exports ? this
cid = global.cid = config.cid
lid = global.lid = config.lid
token = global.token = config.token 
global.bounds = config.bounds
global.addresses = config.addresses
global.pokemons = new MultiRange(config.pokemons.ranges)
global.cnt = 0
global.parallel = parseInt(config.parallel)
start="==================START======================\n"
end  ="==================END========================\n"

work = () ->
  client = []
  body = []
  res = []
  err = []
  global.params = ("bounds":b for b in config.bounds).concat ("address":a for a in config.addresses)
  p = global.params.length
  n = global.cnt
  k = global.parallel
  params = (global.params[i%p] for i in [ n .. n+k-1 ])
  global.cnt = (n + k) % p
  console.log "Scanning..."
  console.log params
  await
    for param,i in params
      client[i] = request.createClient skiplag_url
      url=buildUrl(skiplag_url, queryParams: param)
      client[i].get url, defer err[i],res[i],body[i]
      console.log "Query: #{url}"
  poke = []
  poke = ( b.pokemons for b,i in body when not err[i]?)
  if poke.length > 0
    console.log "Processing Data"
    poke = ( x.filter((t)->global.pokemons.has(t.pokemon_id)) for x in poke when x )
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
    bot.sendMessage(lid,"Urgent. Error Occur. Please check server log.")

bot.on "ready", ()->
  console.log "test"
  bot.sendMessage(lid,"Bot #{bot.user.id} logged in.")
  Repeat(work).every(45, 's').start()

bot.on "message", (msg)->
  if msg.author == bot.user then return
  if not msg.content.startsWith("feeder") then return
  regex = new RegExp(/feeder (\w+) (a|b|p)($| (.*))/)
  docs="""
    Usage: feeder COMMAND
      where COMMAND is one of the following:
        ls [a|b|p]               : list all search addresses/bounds/pokemons
        rm [a|b|p] ID[,ID,...]   : remove address/bound/pokemon with given IDs
        add a ADDRESS          : add a given address
        add b BOUNDS           : add a given BOUNDS of the form NUM,NUM,NUM,NUM
        add p ID[,ID,...]      : add pokemon ID
        set p NUM              : set NUM region parallel search
        hello a                : return Hello World (For Testing only)
  """
  match = msg.content.match(regex)
  reply = (msg) -> bot.sendMessage lid, msg
  if not match
    reply docs
    return
  updated=false
  switch match[1]
    when "hello"
      if match[2]=="a"
        reply "Hello World"
    when "ls"
      if match[2]=="a"
        reply ("#{i}:#{a}" for a,i in global.addresses).join("\n")
      else if match[2]=="b"
        reply ("#{i}:#{b}" for b,i in global.bounds).join("\n")
      else if match[2]=="p"
        reply global.pokemons
    when "add"
      updated=true
      if match[2]=="a"
        global.addresses.push match[4]
      else if match[2]=="b"
        global.bounds.push match[4]
      else if match[2]=="p"
        global.pokemons.append match[4]
    when "rm"
      updated=true
      ids = match[4].split(",").map((x)->parseInt(x))
      if match[2]=="a"
        global.addresses = (a for a,i in global.addresses when i not in ids)
      else if match[2]=="b"
        global.bounds = (b for b,i in global.bounds when i not in ids)
      else if match[2]=="p"
        global.pokemons.subtract match[4]
    when "set"
      updated=true
      if match[2]=="p"
        global.parallel=parseInt(match[4])
  if updated
    jsonfile.writeFile(config_file, global, spaces: 4)
    reply "Updated."


bot.loginWithToken(token)


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
