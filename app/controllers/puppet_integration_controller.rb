class PuppetIntegrationController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def classify
    server = Server.where(:fqdn => params['fqdn']).first
    raise ActionController::RoutingError.new('Not Found') if params[:key] != PUPPET_KEY || server.nil? || !server.deploy.valid?

    @app_servers = []
    server.deploy.servers.each do |serv|
      if serv.classes.include? "appserver"
        @app_servers << serv.ip_address
      end
    end

    config = {'classes' => {'common' => ''}}
    config['parameters'] = {}
    config['parameters']['rails_env'] = server.deploy.rails_environment 
    config['parameters']['ruby_version'] = server.deploy.ruby_version
    config['parameters']['unicorn_workers'] = server.number_unicorn_workers
    config['parameters']['server_ip'] = server.ip_address
    config['parameters']['app_server_ips'] = @app_servers

    config['parameters']['loadbalancer'] = server.has_class?('loadbalancer')

    if server.deploy.deploy_demo && server.deploy.spree_version.demo_git_url.present?
      config['parameters']['deploy_demo'] = server.deploy.deploy_demo
      config['parameters']['spree_git_url'] = server.deploy.spree_version.demo_git_url
    end

    if server.has_class? 'appserver'
      config['classes']['appserver'] = ''
    end

    if server.has_class? 'dbserver'
      config['classes']['dbserver'] = ''

      if server.has_class? 'appserver'
        config['parameters']['db_server'] = '127.0.0.1'
      else
        config['parameters']['db_server'] = server.ip_address
      end
    else
      db = server.deploy.servers.where("servers.classes like '%dbserver%'").first
      config['parameters']['db_server'] = db.ip_address
    end

    if server.has_class? 'utilserver'
      config['classes']['utilserver'] = ''
    end

    config['classes']['app'] = ''

    # set teh application name, could be a string containing a comma which 
    # means multiple applications, so we need to split it
    #
    config['parameters']['app_name'] = server.deploy.custom_app_name.to_s.split(',')

    # if not set, fallback to just spree as the app name
    if config['parameters']['app_name'].empty?
      config['parameters']['app_name'] = 'spree'
    end

    #allows extra classes to be assigned to each server
    server.custom_classes.to_s.split(',').each do |klass|
      config['classes'][klass] = ''
    end

    render :text => YAML.dump(config)
  end

  def report
    body = request.body.read
    body.gsub! /!ruby\/object:(\w+::)+\w+/, '' #drop serialization
    report = YAML.load(body)

    server = Server.where(:fqdn => report['host']).first

    server.last_puppet_run = report['time']
    server.last_puppet_result = report['status']
    server.save

    render :text => 'ok'
  end
end

