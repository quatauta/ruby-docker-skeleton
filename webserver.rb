#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Include requierments
require "sinatra/base"
require "logger"
require "webrick"
require "yaml"
require "prometheus/client"

#
# Load the model
require "./model.rb"

#
# Sync to standard-out
$stdout.sync = true

class Webserver < Sinatra::Base

  #
  # Start the configuration/pre-run
  configure do

    #
    # Get JSON-logging
    $logger = Logger.new(STDOUT)
    $logger.formatter = proc do |severity, datetime, progname, msg|
      if msg.class == Hash
        hash = {timestamp: datetime.strftime("%F %T.%L"), severity: severity}.merge(msg)
        puts hash.to_json
      else
        hash = {timestamp: datetime.strftime("%F %T.%L"), severity: severity, message: msg}
        puts hash.to_json
      end
    end

    #
    # Fix more logging
    $logger.info({:message => "Starting the webserver"})
    $logger.level = Logger::INFO
    set :logger, $logger

    #
    # Set up env and variabels
    username = ENV["USERNAME"]
    password = ENV["PASSWORD"]

    #
    # Set up Prometheus
    prometheus = Prometheus::Client.registry
    @@requests_total = Prometheus::Client::Counter.new(:requests_total, docstring: "total_requests", labels: [:service])
    prometheus.register(@@requests_total)
    @@model = Model.new(username, password)
    $logger.info({:message => "Configuration done!"})

  end


  #
  # Base-endpoint for Kubernetes
  get "/readiness" do
    data = "{\"status\":\"ok\"}\n"
    content_type :json
    [200, [data]]
  end


  #
  # Base-endpoint for Kubernetes
  get "/ping" do
    $logger.info({:message => "rack GET /ping"})

    @@requests_total.increment(labels: { service: "ping" })
    data = "{\"status\":\"ok\"}\n"
    content_type :json
    [200, [data]]
  end


  #
  # Base-endpoint
  get "/" do
    $logger.info({:message => "rack GET /"})

    data = "{\"status\":\"ok\"}\n"
    content_type :json
    [200, [data]]
  end

end
