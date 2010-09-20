# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Set::Dynamic < Bike::Field

  include Bike::Set

  attr_reader :storage, :workflow

  def initialize(meta = {})
    @meta        = meta
    @storage     = Bike::Storage.instance self
    @workflow    = Bike::Workflow.instance self
    @meta        = @workflow.class.const_get(:DEFAULT_META).merge @meta
    @item_object = {}

    my[:item] ||= {
      'default' => {:item => {}}
    }
    my[:item].each {|type, item_meta|
      item_meta[:item] = @workflow.default_sub_items.merge item_meta[:item]
    }

    my[:p_size] = meta[:max] if meta[:max]
    my[:preview] = :optional if Array(meta[:tokens]).include?('may_preview')
    my[:preview] = :mandatory if Array(meta[:tokens]).include?('should_preview')
    my[:order] = 'id'  if Array(meta[:tokens]).include? 'asc'
    my[:order] = '-id' if Array(meta[:tokens]).include? 'desc'
  end

  def meta_href
    "#{Bike.uri}#{my[:path]}/"
  end

  def meta_tid
    unless @meta[:tid]
      t = Time.now
      @meta[:tid] = t.strftime('%m%d%H%M%S.') + t.usec.to_s
    end
    @meta[:tid]
  end

  def get(arg = {})
    if !arg[:conds].is_a?(::Hash) || arg[:conds].empty?
      arg[:conds] = my[:conds].is_a?(::Hash) ? my[:conds].dup : {}
    end
    super
  end

  def commit(type = :temp)
    @workflow.before_commit

    items = pending_items
    items.each {|id, item|
      item.commit(:temp) || next
      case type
        when :temp
          store(id, item) if @storage.is_a? Bike::Storage::Temp
        when :persistent
          store(id, item)
          item.commit :persistent
      end
    }
    if valid?
      @result = (@action == :update) ? items : @action
      @action = nil if type == :persistent
      @workflow.after_commit
      self
    end
  end

  private

  def _val
    @storage.val
  end

  def _get(arg)
    (@workflow._get(arg) || super) unless @workflow._hide? arg
  end

  def _get_by_tmpl(arg, tmpl = '')
    if arg[:action] == :read || self != Bike.base
      super
    else
      base_path = Bike.transaction[my[:tid]].is_a?(Bike::Field) ? nil : my[:base_path]
      action = "#{base_path}/#{my[:tid]}/update.html"
      <<_html
<form id="form_#{my[:name]}" method="post" enctype="multipart/form-data" action="#{action}">
<input name="_token" type="hidden" value="#{Bike.token}" />
#{super}</form>
_html
    end
  end

  def _get_by_self_reference(arg)
    super unless @workflow._hide?(arg)
  end

  def permit_get?(arg)
    permit?(arg[:action]) || collect_item(arg[:conds] || {}).all? {|item|
      item[:id][Bike::REX::ID_NEW] ?
        item.permit?(:create) :
        item.send(:permit_get?, :action => arg[:action])
    }
  end

  def _post(action, v = nil)
    if action == :create
      @storage.build({})
      @item_object.clear
    end

    case action
      when :create, :update
        v.keys.sort_by {|id| id.to_s }.each {|id|
          next unless id.is_a? ::String

          v[id][:action] ||= id[Bike::REX::ID_NEW] ? :create : :update
          item_instance(id).post(v[id][:action], v[id])
        }
      when :load, :load_default
        @storage.build v
    end

    !pending_items.empty? || action == :delete
  end

  def store(id, item)
    case item.action
      when :create
        return if id[Bike::REX::ID] || item.empty?
        new_id = @storage.store(:new_id, item.val)
        item[:id] = new_id
        @item_object.delete id
        @item_object[item[:id]] = item
      when :update, nil
        new_id = @storage.store(item[:id], item.val)
        if new_id != item[:id]
          @item_object[new_id] = @item_object.delete item[:id]
          item[:id] = new_id
        end
      when :delete
        @storage.delete id
        @item_object.delete id
    end
  end

  def collect_item(conds = {}, &block)
    @storage.select(conds).collect {|id|
      item = item_instance id
      block ? block.call(item) : item
    }
  end

  def item_instance(id, type = 'default')
    unless @item_object[id]
      item_meta = my[:item][type] || my[:item]['default']
      @item_object[id] = Bike::Field.instance(
        item_meta.merge(
          :id     => id,
          :parent => self,
          :klass  => 'set-static'
        )
      )
      if id[Bike::REX::ID_NEW]
        @item_object[id].load_default
      else
        @item_object[id].load @storage.val(id)
      end
    end
    @item_object[id]
  end

end
