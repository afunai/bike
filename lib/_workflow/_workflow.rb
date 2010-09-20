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

  def self.instance(sd)
    klass = sd[:workflow].to_s.capitalize
    if klass != ''
      self.const_get(klass).new sd
    else
      self.new sd
    end
  end

  def self.roles(roles)
    %w(admin group owner user none).select {|r|
      roles & const_get("ROLE_#{r.upcase}") > 0
    }.collect{|r| Bike::I18n._ r }
  end

  attr_reader :sd

  def initialize(sd)
    @sd = sd
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
    @sd.instance_eval {
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

  def next_action(base)
    (!base.result || base.result.values.all? {|item| item.permit? :read }) ? :read_detail : :done
  end

end
