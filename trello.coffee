# Description:
#   Add entries to trello directly from hubot
#
# Dependencies:
#   "node-trello": "0.1.2"
#
# Configuration:
#   HUBOT_TRELLO_KEY - your trello developer key
#
# Commands:
#   hubot trello all the users - which users do we know about trello for
#   hubot trello get token - provides instructions on acquiring a token
#   hubot trello set token <token> - set the authentication token
#   hubot trello forget me - deletes the authentication token
#   hubot trello boards - list your trello boards
#   hubot trello set my board to <board> - set your default board
#   hubot trello lists - list your trello lists on the default board
#   hubot trello set my list to <list> - set your default list
#   hubot trello me <message> - add a new card to your default list
#
# Notes:
#   Currently cards can only be added to your default list/board although
#   this can be changed
#
# Author:
#   beezly

module.exports = (robot) ->
  Trello = require 'node-trello'
  
  trello_key = process.env.HUBOT_TRELLO_KEY

  robot.respond /trello all the users/i, (msg) ->
    theReply = "Here is who I know:\n"

    for own key, user of robot.brain.data.users
      if(user.trellotoken)
        theReply += user.name + "\n"

    msg.send theReply

  robot.respond /trello get token/, (msg) ->
    msg.send "Get a token from https://trello.com/1/authorize?key=#{trello_key}&name=cicsbot&expiration=30days&response_type=token&scope=read,write"
    msg.send "Then send it back to me as \"trello add token <token>\""

  robot.respond /trello add token ([a-f0-9]+)/i, (msg) ->

    trellotoken = msg.match[1]
    msg.message.user.trellotoken = trellotoken
    msg.send "Ok, your token is registered"

  robot.respond /trello forget me/i, (msg) ->
    user = msg.message.user
    user.trellotoken  = null

    msg.reply("Ok, I have no idea who you are anymore.")

  robot.respond /trello boards/i, (msg) ->
    user = msg.message.user
    trellotoken = msg.message.user.trellotoken
    t = new Trello trello_key, trellotoken
    t.get '/1/members/me/boards/', (err,data) ->
      console.log board for board in data
      msg.send board.name for board in data

  robot.respond /trello set my board to (.*)/i, (msg) ->
    board_name = msg.match[1]
    user = msg.message.user
    trellotoken = msg.message.user.trellotoken
    t = new Trello trello_key, trellotoken
    t.get '/1/members/me/boards/', (err, data) -> 
      for board in data
        if board.name == board_name
          user.trelloboard = board.id
          msg.reply "Your trello board is set to #{board.name}"
  
  robot.respond /trello lists/i, (msg) ->
    user = msg.message.user
    trellotoken = user.trellotoken
    trelloboard = user.trelloboard
    t = new Trello trello_key, trellotoken
    if !trellotoken
      msg.reply "You have no trellotoken"
    else if !trelloboard 
      msg.reply "You have no trelloboard"
    else 
      t.get "/1/boards/#{trelloboard}/lists", (err, data) ->
        msg.send list.name for list in data
    

   robot.respond /trello set my list to (.*)/i, (msg) ->
     list_name = msg.match[1]
     user = msg.message.user
     trellotoken = user.trellotoken
     trelloboard = user.trelloboard
     t = new Trello trello_key, trellotoken
     if !trellotoken
       msg.reply "You have no trellotoken"
     else if !trelloboard
       msg.reply "You have no trelloboard"
     else
       t.get "/1/boards/#{trelloboard}/lists", (err, data) ->
         for list in data
           if list.name == list_name
             user.trellolist = list.id
             msg.reply "Your trello list is set to #{list.name}"
      
  robot.respond /trello me (.*)/i, (msg) ->
    content = msg.match[1]
    user = msg.message.user
    trelloboard = user.trelloboard
    trellotoken = user.trellotoken
    trellolist = user.trellolist
    if !trellotoken
      msg.reply "You don't seem to have a trello token registered. Use \"trello get token\"."
    else if !trelloboard
      msg.reply "You don't seem to have a default trello board configured. Use \"trello my board is\" to do that"
    else if !trellolist
      msg.reply "You don't seem to have a default trello list configured. Use \"trello my list is \" to do that"
    else 
      t = new Trello trello_key, trellotoken
      t.post "/1/lists/#{trellolist}/cards", { name: content }, (err, data) -> 
        msg.reply "Added to your list - #{data.url}"
        

