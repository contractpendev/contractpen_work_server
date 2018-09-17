
Comedy = require 'comedy'
Awilix = require 'awilix'
Winston = require 'winston'
Graph = require '@dagrejs/graphlib'
ClusterWS = require 'clusterws'
express = require 'express'
GlobalContainer = require './GlobalContainer'
bodyParser = require 'body-parser'

Worker = ->
  wss = @wss
  server = @server

  graphClass = Graph.Graph
  graphInstance = new graphClass()

  # Logging
  logger = Winston.createLogger(transports: [
    new (Winston.transports.File)(filename: 'application.log')
  ])

  logger.log('info', 'Startup')

  # Setup
  actorSystem = Comedy()
  actorSystem.getLog().setLevel(0) # Prevent output of log at startup

  app = express()
  app.use(bodyParser.json())
  router = express.Router()

  # Dependency injection
  # @todo How to get the container to be globally available
  GlobalContainer.container = Awilix.createContainer
    injectionMode: Awilix.InjectionMode.PROXY

  GlobalContainer.container.register
    container: Awilix.asValue GlobalContainer.container
    logger: Awilix.asValue logger
    actorSystem: Awilix.asValue actorSystem
    graphClass: Awilix.asClass graphClass
    graph: Awilix.asValue graphInstance
    expressRouter: Awilix.asValue router

  opts = {}

  GlobalContainer.container.loadModules [
      'src/services/*.js'
    ], opts

  setupServer = GlobalContainer.container.resolve 'SetupServer'
  setupServer.setup()

  #app.use express.static('public')

  app.use '/api', router

  # Connect ClusterWS and Express
  server.on 'request', app
  wss.on 'connection', (socket) ->
    console.log 'New socket is connected'
    return


class Setup

  setup: () ->
    @clusterws = new ClusterWS(
      worker: Worker
      port: 3050)

module.exports = Setup
