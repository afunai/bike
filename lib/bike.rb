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

    begin
      if params[:action] == :logout && params[:token] == Bike.token
        logout(base, params)
      elsif method == 'get'
        get(base, params)
      elsif params[:action] == :login
        login(base, params)
      elsif params[:action] == :preview
        preview(base, params)
      elsif params[:token] != Bike.token
        Bike::Response.forbidden(:body => 'invalid token')
      elsif Bike.transaction[tid] && !Bike.transaction[tid].is_a?(Bike::Field)
        Bike::Response.unprocessable_entity(:body => 'transaction expired')
      else
        begin
          post(base, params)
        rescue Bike::Error::Forbidden
          Bike::Response.forbidden
        end
      end
    rescue Bike::Error::Forbidden
      if params[:action] && Bike.client == 'nobody'
        params[:dest_action] = (method == 'post') ? :index : params[:action]
        params[:action] = :login
      end
      Bike::Response.unprocessable_entity(:body => _get(base, params)) rescue Bike::Response.forbidden
# TODO: rescue Error::System etc.
    end
  end

  private

  def login(base, params)
    user = Bike::Set::Static::Folder.root.item('_users', 'main', params['id'].to_s)
    if user && params['pw'].to_s.crypt(user.val('password')) == user.val('password')
      Bike.client = params['id']
    else
      Bike.client = nil
      raise Bike::Error::Forbidden
    end
    path   = Bike::Path.path_of params[:conds]
    action = (params['dest_action'] =~ /\A\w+\z/) ? params['dest_action'] : 'index'
    Bike::Response.see_other(
      :location => "#{Bike.uri}#{base[:path]}/#{path}#{action}.html"
    )
  end

  def logout(base, params)
    Bike.client = nil
    path = Bike::Path.path_of params[:conds]
    Bike::Response.see_other(
      :location => "#{Bike.uri}#{base[:path]}/#{path}index.html"
    )
  end

  def get(base, params)
    if base.is_a? Bike::File
      body = (params[:sub_action] == :small) ? base.thumbnail : base.body
      Bike::Response.ok(
        :headers => {
          'Content-Type'   => base.val['type'],
          'Content-Length' => body.to_s.size.to_s,
        },
        :body    => body
      )
    else
      Bike::Response.ok :body => _get(base, params)
    end
  end

  def preview(base, params)
    Bike.transaction[base[:tid]] ||= base if base[:tid] =~ Bike::REX::TID

    base.update params
    if base.commit(:temp) || params[:sub_action] == :delete
      id_step = result_step(base, params)
      action = "preview_#{params[:sub_action]}"
      Bike::Response.see_other(
        :location => "#{Bike.uri}/#{base[:tid]}/#{id_step}#{action}.html"
      )
    else
      params = {:action => :update}
      params[:conds] = {:id => base.errors.keys}
      return Bike::Response.unprocessable_entity(:body => _get(base, params))
    end
  end

  def post(base, params)
    Bike.transaction[base[:tid]] ||= base if base[:tid] =~ Bike::REX::TID

    base.update params
    if params[:status]
      if base[:folder].commit :persistent
        Bike.transaction[base[:tid]] = result_summary base
        action = base.workflow.next_action base
        id_step = result_step(base, params) if base[:parent] == base[:folder] && action != :done
        Bike::Response.see_other(
          :location => "#{Bike.uri}/#{base[:tid]}#{base[:path]}/#{id_step}#{action}.html"
        )
      else
        params = {:action => :update}
        params[:conds] = {:id => base.errors.keys}
        Bike::Response.unprocessable_entity :body => _get(base, params)
      end
    else
      base.commit :temp
      id_step = result_step(base, params)
      Bike::Response.see_other(
        :location => "#{Bike.uri}/#{base[:tid]}/#{id_step}update.html"
      )
    end
  end

  def result_summary(base)
    (base.result || {}).values.inject({}) {|summary, item|
      item_result = item.result.is_a?(::Symbol) ? item.result : :update
      summary[item_result] = summary[item_result].to_i + 1
      summary
    }
  end

  def result_step(base, params)
    if base.result
      id = base.result.values.collect {|item| item[:id] }
    else
      id = params.keys.select {|id|
        id.is_a?(::String) && (id[Bike::REX::ID] || id[Bike::REX::ID_NEW])
      }
    end
    Bike::Path.path_of(:id => id)
  end

  def _get(f, params)
    params[:action] ||= f.default_action
    until f.is_a? Bike::Set::Static::Folder
      params = {
        :action     => (f.default_action == :read) ? :read : nil,
        :sub_action => f.send(:summary?, params) ? nil : (params[:sub_action] || :detail),
        f[:id]      => params,
      }
      params[:conds] = {:id => f[:id]} if f[:parent].is_a? Bike::Set::Dynamic
      f = f[:parent]
    end if f.is_a? Bike::Set::Dynamic

    f.get params
  end

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
      else
        hash[item_id] = val
      end

      params
    }
  end

end
