# Description:
#   Get ElasticSearch Cluster Information
#
# Commands:
#   hubot: elasticsearch cluster [server] - Gets the cluster information for the given server
#   hubot: elasticsearch node [server] - Gets the node information for the given server
#   hubot: elasticsearch query [server] [query] - Runs a specific query against an ElasticSearch cluster
#
# Notes:
#   The server must be a fqdn (with the port!) to get to the elasticsearch cluster
#
# Author:
#  Paul Stack


module.exports = (robot) ->

  search = (msg, server, query) ->
    msg.http("http://#{server}/_search?#{query}")
    msg.send("Server http://#{server}/_search?#{query}")
      #.get() (err, res, body) ->
      #  json = JSON.parse(body)
      #  msg.send("end")

  cluster_health = (msg, server) ->
    msg.http("http://#{server}/_cluster/health")
      .get() (err, res, body) ->
        json = JSON.parse(body)
        cluster_name=['cluster']
        status = json['status']
        number_of_nodes = json['number_of_nodes']
        msg.send "Cluster: #{cluster_name} \nStatus: #{status} \n Nodes: #{number_of_nodes}"

  node_health = (msg, server) ->
    msg.http("http://#{server}/_status")
      .get() (err, res, body) ->
        json = JSON.parse(body)
        name =['name']
        status = json['status']
        msg.send "Server: #{name} \nStatus: #{status}"

  robot.respond /elasticsearch query (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    search msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)


  robot.respond /elasticsearch node (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    node_health msg, msg.match[1], (text) ->
      msg.send text

  robot.respond /elasticsearch cluster (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    cluster_health msg, msg.match[1], (text) ->
      msg.send text