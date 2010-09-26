# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike

  lib_dir = ::File.dirname __FILE__

  require "#{lib_dir}/_i18n.rb"
  I18n.bindtextdomain('index', ::File.expand_path('../locale', lib_dir))

  Dir["#{lib_dir}/_*.rb"].sort.each {|file| require file }
  Dir["#{lib_dir}/[a-z]*/*.rb"].sort.each {|file| require file }
  Dir["#{lib_dir}/_*/*.rb"].sort.each {|file| require file }

  module REX
    ID_SHORT   = /[a-z][a-z0-9]*/
    ID         = /^(\d{8})_(\d{4,}|#{ID_SHORT})/
    ID_NEW     = /^_\d/
    COND       = /^(.+?)=(.+)$/
    COND_D     = /^(19\d\d|2\d\d\d|9999)\d{0,4}$/
    PATH_ID    = /\/((?:19|2\d)\d{6})\/(\d+)/
    TID        = /\d{10}\.\d+/
    DIR_STATIC = /css|js|img|imgs|image|images/
  end

  def self.config(config)
    @config = config
  end

  def self.[](name)
    @config ||= {}
    @config[name]
  end

  def self.current
    Thread.current
  end

  def self.session
    self.current[:session] || ($fake_session ||= {})
  end

  def self.transaction
    self.session[:transaction] ||= {}
  end

  def self.client
    self.session[:client] ||= 'nobody'
  end

  def self.client=(id)
    self.session[:client] = id
  end

  def self.token
    self.session[:token] ||= rand(36 ** 32).to_s(36)
  end

  def self.base
    self.current[:base]
  end

  def self.uri
    self.current[:uri]
  end

  def self.libdir
    ::File.dirname __FILE__
  end

  def self.static(env)
    @static ||= Rack::Directory.new Bike['skin_dir']
    response = @static.call env

    if response.first == 404
      until ::File.readable? ::File.join(
        Bike['skin_dir'],
        env['PATH_INFO'].sub(%r{(/#{Bike::REX::DIR_STATIC}/).*}, '\\1')
      )
        env['PATH_INFO'].sub!(%r{/[^/]+(?=/#{Bike::REX::DIR_STATIC}/)}, '') || break
      end
      @static.call env
    else
      response
    end
  end

  def call(env)
    uri    = "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{env['SCRIPT_NAME']}"
    req    = Rack::Request.new env
    method = req.request_method.downcase
    params = params_from_request req
    path   = req.path_info
    tid    = Bike::Path.tid_of path

    static_path = ::File.expand_path path
    return Bike.static(env) if (
      static_path =~ %r{/#{Bike::REX::DIR_STATIC}/} &&
      static_path !~ %r{/#{Bike::REX::TID}/} &&
      static_path !~ %r{/#{Bike::REX::ID.to_s.sub('^','')}/}
    )

    Bike::I18n.lang = env['HTTP_ACCEPT_LANGUAGE']

    Bike.current[:env]     = env
    Bike.current[:uri]     = uri
    Bike.current[:req]     = req
    Bike.current[:session] = env['rack.session']

    if Bike.transaction[tid].is_a? Bike::Field
      base = Bike.transaction[tid].item Bike::Path.steps_of(path.sub(/\A.*#{Bike::REX::TID}/, ''))
    else
      base = Bike::Path.base_of path
    end
    return Bike::Response.not_found unless base

    base[:tid] = tid
    Bike.current[:base] = base

    base.workflow.call(method, params)
  end

  private

  def params_from_request(req)
    params = {
      :action     => Bike::Path.action_of(req.path_info),
      :sub_action => Bike::Path.sub_action_of(req.path_info),
    }
    params.merge! rebuild_params(req.params)

    params[:conds] ||= {}
    params[:conds].merge! Bike::Path.conds_of(req.path_info)

    params
  end

  def rebuild_params(src)
    src.keys.sort.reverse.inject({}) {|params, key|
      name, special = key.split('.', 2)
      steps = name.split '-'

      if special
        special_id, special_val = special.split('-', 2)
      else
        item_id = steps.pop
      end

      hash = steps.inject(params) {|v, k| v[k] ||= {} }
      val  = src[key]

      if special_id == 'action'
        action, sub_action = (special_val || val).split('_', 2)
        hash[:action] = action.intern
        hash[:sub_action] = sub_action.intern if sub_action
      elsif special_id == 'status'
        hash[:status] = (special_val || val).intern
      elsif special_id == 'conds'
        hash[:conds] ||= {}
        hash[:conds][special_val.intern] = val
      elsif hash[item_id].is_a? ::Hash
        hash[item_id][:self] = val
      elsif item_id == '_token'
        hash[:token] = val
      elsif item_id == 'dest_action'
        hash[:dest_action] = val
      else
        hash[item_id] = val
      end

      params
    }
  end

end
