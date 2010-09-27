# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Workflow

  include Bike::I18n

  DEFAULT_META = {
    :item_label => Bike::I18n.n_('item', 'items', 1),
  }
  DEFAULT_SUB_ITEMS = {}

  ROLE_ADMIN = 0b10000
  ROLE_GROUP = 0b01000
  ROLE_OWNER = 0b00100
  ROLE_USER  = 0b00010
  ROLE_NONE  = 0b00001

  PERM = {
    :create => 0b11111,
    :read   => 0b11111,
    :update => 0b11111,
    :delete => 0b11111,
  }

  def self.instance(f)
    klass = (f[:sd] && f[:sd][:workflow]).to_s.capitalize
    if klass != ''
      self.const_get(klass).new f
    else
      self.new f
    end
  end

  def self.roles(roles)
    %w(admin group owner user none).select {|r|
      roles & const_get("ROLE_#{r.upcase}") > 0
    }.collect{|r| Bike::I18n._ r }
  end

  attr_reader :f

  def initialize(f)
    @f = f
  end

  def call(method, params)
    (method == 'post') ? post(params) : get(params)
  rescue Bike::Error::Forbidden
    if params[:action] && Bike.client == 'nobody'
      params[:dest_action] ||= (method == 'post') ? :index : params[:action]
      params[:action] = :login
    end
    Bike::Response.unprocessable_entity(:body => __g_default(params)) rescue Bike::Response.forbidden
# TODO: rescue Error::System etc.
  end

  def get(params)
    if @f.is_a? Bike::File
      body = (params[:sub_action] == :small) ? @f.thumbnail : @f.body
      Bike::Response.ok(
        :headers => {
          'Content-Type'   => @f.val['type'],
          'Content-Length' => body.to_s.size.to_s,
        },
        :body    => body
      )
    else
      m = "_g_#{params[:action]}"
      respond_to?(m, true) ? __send__(m, params) : _g_default(params)
    end
  end

  def post(params)
    m = "_p_#{params[:action]}"
    respond_to?(m, true) ? __send__(m, params) : _p_default(params)
  end

  def default_sub_items
    self.class.const_get :DEFAULT_SUB_ITEMS
  end

  def permit?(roles, action)
    case action
      when :login, :done, :message
        true
      when :preview
        # TODO: permit?(roles, action, sub_action = nil)
        (roles & self.class.const_get(:PERM)[:read].to_i) > 0
      else
        (roles & self.class.const_get(:PERM)[action].to_i) > 0
    end
  end

  def _get(arg)
    @f.instance_eval {
      if arg[:action] == :create
        item_instance '_001'
        _get_by_tmpl({:action => :create, :conds => {:id => '_001'}}, my[:tmpl][:index])
      end
    }
  end

  def _hide?(arg)
    (arg[:p_action] && arg[:p_action] != :read) ||
    (arg[:orig_action] == :read && arg[:action] == :submit)
  end

  def before_commit
  end

  def after_commit
  end

  private

  def _g_default(params)
    Bike::Response.ok :body => __g_default(params)
  end

  def __g_default(params)
    f = @f
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

    f.get(params)
  end

  def _p_default(params)
    res = __p_validate params
    return res if res

    __p_set_transaction
    __p_update params

    if params[:status]
      if @f[:folder].commit :persistent
        Bike.transaction[@f[:tid]] = result_summary
        id_step = result_step(params) if @f[:parent] == @f[:folder] && next_action != :done
        Bike::Response.see_other(
          :location => "#{Bike.uri}/#{@f[:tid]}#{@f[:path]}/#{id_step}#{next_action}.html"
        )
      else
        params = {:action => :update}
        params[:conds] = {:id => @f.errors.keys}
        Bike::Response.unprocessable_entity :body => __g_default(params)
      end
    else
      @f.commit :temp
      id_step = result_step(params)
      Bike::Response.see_other(
        :location => "#{Bike.uri}/#{@f[:tid]}/#{id_step}update.html"
      )
    end
  end

  def _p_preview(params)
    res = __p_validate params
    return res if res

    __p_set_transaction
    __p_update params

    if @f.commit(:temp) || params[:sub_action] == :delete
      id_step = result_step(params)
      action = "preview_#{params[:sub_action]}"
      Bike::Response.see_other(
        :location => "#{Bike.uri}/#{@f[:tid]}/#{id_step}#{action}.html"
      )
    else
      params = {:action => :update}
      params[:conds] = {:id => @f.errors.keys}
      Bike::Response.unprocessable_entity(:body => __g_default(params))
    end
  end

  def _p_login(params)
    user = Bike::Set::Static::Folder.root.item('_users', 'main', params['id'].to_s)
    if user && params['pw'].to_s.crypt(user.val('password')) == user.val('password')
      Bike.client = params['id']
    else
      Bike.client = nil
      raise Bike::Error::Forbidden
    end
    path   = Bike::Path.path_of params[:conds]
    action = (params[:dest_action] =~ /\A\w+\z/) ? params[:dest_action] : 'index'
    Bike::Response.see_other(
      :location => "#{Bike.uri}#{@f[:path]}/#{path}#{action}.html"
    )
  end

  def _p_logout(params)
    return Bike::Response.forbidden(:body => 'invalid token') unless params[:token] == Bike.token

    Bike.client = nil
    path = Bike::Path.path_of params[:conds]
    Bike::Response.see_other(
      :location => "#{Bike.uri}#{@f[:path]}/#{path}index.html"
    )
  end
  alias :_g_logout :_p_logout

  def __p_validate(params)
    if params[:token] != Bike.token
      Bike::Response.forbidden(:body => 'invalid token')
    elsif Bike.transaction[@f[:tid]] && !Bike.transaction[@f[:tid]].is_a?(Bike::Field)
      Bike::Response.unprocessable_entity(:body => 'transaction expired')
    end
  end

  def __p_set_transaction
    Bike.transaction[@f[:tid]] ||= @f if @f[:tid] =~ Bike::REX::TID
  end

  def __p_update(params)
    @f.update params
  end

  def result_summary
    (@f.result || {}).values.inject({}) {|summary, item|
      item_result = item.result.is_a?(::Symbol) ? item.result : :update
      summary[item_result] = summary[item_result].to_i + 1
      summary
    }
  end

  def result_step(params)
    if @f.result
      id = @f.result.values.collect {|item| item[:id] }
    else
      id = params.keys.select {|id|
        id.is_a?(::String) && (id[Bike::REX::ID] || id[Bike::REX::ID_NEW])
      }
    end
    Bike::Path.path_of(:id => id)
  end

  def next_action
    (!@f.result || @f.result.values.all? {|item| item.permit? :read }) ? :read_detail : :done
  end

end
