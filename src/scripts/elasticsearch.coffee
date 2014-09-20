# Description:
#   Get ElasticSearch Cluster Information
#
# Commands:
#   hubot: elasticsearch cluster health [cluster]     - Gets the cluster health for the given server or alias
#   hubot: elasticsearch cat nodes [cluster]          - Gets the information from the cat nodes endpoint for the given server or alias
#   hubot: elasticsearch cat indexes [cluster]        - Gets the information from the cat indexes endpoint for the given server or alias
#   hubot: elasticsearch clear cache [cluster]        - Clears the cache for the specified cluster
#   hubot: elasticsearch cluster settings [cluster]   - Gets a list of all of the settings stored for the cluster
#   hubot: elasticsearch disable allocation [cluster] - disables shard allocation to allow nodes to be taken offline
#   hubot: elasticsearch enable allocation [cluster]  - renables shard allocation
#   hubot: elasticsearch show aliases                 - shows the aliases for the list of ElasticSearch instances
#   hubot: elasticsearch add alias [alias name] [url] - sets the alias for a given url
#   hubot: elasticsearch clear alias [alias name]     - please note that this needs to include any port numbers as appropriate
#
# Notes:
#   The server must be a fqdn (with the port!) to get to the elasticsearch cluster
#
# Author:
#  Paul Stack

_esAliases = {}

QS = require 'querystring'

module.exports = (robot) ->

  robot.brain.on 'loaded', ->
    if robot.brain.data.elasticsearch_aliases?
      _esAliases = robot.brain.data.elasticsearch_aliases

  clusterHealth = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.http("#{cluster_url}/_cluster/health?pretty=true")
        .get() (err, res, body) ->
          json = JSON.parse(body)
          msg.send("/code #{json}")

  catNodes = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the cat stats for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/nodes?h=host,heapPercent,load,segmentsMemory,fielddataMemory,filterCacheMemory,idCacheMemory,percolateMemory,u,heapMax,nodeRole,master")
        .get() (err, res, body) ->
          lines  = body.split("\n")
          header = lines.shift()
          list   = [header].concat(lines.sort().reverse()).join("\n")
          msg.send("/code #{list}")

  catIndexes = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Getting the cat indices for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/indices/logstash-*?h=idx,sm,fm,fcm,im,pm,ss,sc,dc&v")
        .get() (err, res, body) ->
          lines  = body.split("\n")
          header = lines.shift()
          list   = [header].concat(lines.sort().reverse()).join("\n")
          msg.send("/code #{list}")

  clearCache = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Clearing the cache for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cache/clear")
        .post() (err, res, body) ->
          json = JSON.parse(body)
          shards = json['_shards']['total']
          successful = json['_shards']['successful']
          failure = json['_shards']['failed']
          msg.send "Results: \n Total Shards: #{shards} \n Successful: #{successful} \n Failure: #{failure}"

  disableAllocation = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Disabling Allocation for the cluster #{cluster_url}")

      data = {
        'transient': {
          'cluster.routing.allocation.enable': 'none'
        }
      }

      json = JSON.stringify(data)
      msg.http("#{cluster_url}/_cluster/settings")
        .put(json) (err, res, body) ->
          msg.send("/code #{body}")

  enableAllocation = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Enabling Allocation for the cluster #{cluster_url}")

      data = {
        'transient': {
          'cluster.routing.allocation.enable': 'all'
        }
      }

      json = JSON.stringify(data)
      msg.http("#{cluster_url}/_cluster/settings")
        .put(json) (err, res, body) ->
          msg.send("/code #{body}")

  showClusterSettings = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("Do not recognise the cluster alias: #{alias}")
    else
      msg.send("Gettings the Cluster settings for #{cluster_url}")
      msg.http("#{cluster_url}/_cluster/settings?pretty=true")
        .get() (err, res, body) ->
          msg.send("/code #{body}")

  showAliases = (msg) ->

    if _esAliases == null
      msg.send("I cannot find any ElasticSearch Cluster aliases")
    else
      for alias of _esAliases
        msg.send("I found '#{alias}' as an alias for the cluster: #{_esAliases[alias]}")

  clearAlias = (msg, alias) ->
    delete _esAliases[alias]
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The cluster alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _esAliases[alias] = url
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The cluster alias #{alias} for #{url} has been added to the brain")

  robot.hear /elasticsearch cat nodes (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    catNodes msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cat indexes (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    catIndexes msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cluster settings (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showClusterSettings msg, msg.match[1], (text) ->
      msg.send(text)

  robot.hear /elasticsearch cluster health (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clusterHealth msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.hear /elasticsearch add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.hear /elasticsearch clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /elasticsearch clear cache (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearCache msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /elasticsearch disable allocation (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    disableAllocation msg, msg.match[1], (text) ->
      msg.send(text)
