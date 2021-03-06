# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Bike::Set

  include Enumerable

  def meta_dir
    my[:folder][:dir] if my[:folder]
  end

  def meta_path
    ['main', nil].include?(my[:name]) ?
      my[:dir] :
      "#{my[:dir]}/#{my[:name].sub(/^main-?/, '').gsub('-', '/')}"
  end

  def meta_base_path
    Bike.base ? Bike.base[:path] : my[:path]
  end

  def val(*steps)
    if steps.empty?
      _val
    elsif i = item(steps)
      i.val
    end
  end

  def item(*item_steps)
    item_steps = item_steps.first if item_steps.first.is_a? ::Array
    return self if item_steps.empty?

    id, *item_steps = item_steps

    if id.is_a?(::String) && child = collect_item(:id => id).first
      item = item_steps.empty? ? child : child.item(*item_steps)
      block_given? ? yield(item) : item
    end
  end

  def pending?
    !pending_items.empty? || action
  end

  def errors
    return {} if
      my[:id] =~ Bike::REX::ID_NEW &&
      my[:parent].is_a?(Bike::Set::Dynamic) &&
      my[:parent].workflow.is_a?(Bike::Workflow::Attachment)

    errors = {}
    @item_object.each_pair {|id, item|
      errors[id] = item.errors unless item.valid? || item.action == :delete
    }
    errors
  end

  def collect(&block)
    collect_item({}, &block)
  end

  def each(&block)
    collect_item.each &block
  end

  def inspect_items(indent = 0)
    my_action = action.inspect
    my_result = result.is_a?(::Hash) ?
      result.keys.sort.inspect.sub(/\A\[([\w\W]*)\]\z/, '{\1}') :
      result.inspect

    '  ' * indent +
    "<\"#{my[:id]}\" @action=#{my_action} @result=#{my_result}>\n" +
    @item_object.keys.sort.collect {|id|
      item = @item_object[id]
      if item.respond_to? :inspect_items
        item.inspect_items(indent + 1)
      else
        action = item.action.inspect
        result = item.result.inspect
        val    = item.val.inspect
        '  ' * (indent + 1) + "<\"#{id}\" @action=#{action} @result=#{result} @val=#{val}>\n"
      end
    }.join
  end

  private

  def _get(arg)
    if respond_to?("_g_#{arg[:action]}", true)
      _get_by_method arg
    else
      _get_by_tmpl(arg, action_tmpl(arg))
    end
  end

  def _get_by_tmpl(arg, tmpl = '')
    tmpl.to_s.gsub(/@\((.+?)\)/) {
      tag   = $&
      steps = $1.split '-'
      id    = steps.pop
      item  = item steps
      item ? item[id.intern] : tag
    }.gsub(/_\((.+?)\)/) {
      _ $1
    }.gsub(/\$\((.*?)(?:\.([\w\-]+))?\)/) {
      tag, name, action = $&, $1, $2
      if name == ''
        self_arg = action ?
          arg.merge(:orig_action => arg[:action], :action => action.intern) : arg
        _get_by_self_reference self_arg
      else
        steps = name.split '-'
        item_arg = item_arg(arg, steps)
        item = item steps
        if item.nil?
          tag
        elsif action
          item_arg = item_arg.merge(
            :orig_action => item_arg[:action],
            :action      => action.intern
          )
          item.send(:_get_by_self_reference, item_arg) # skip the authorization
        else
          item.get(item_arg)
        end
      end
    }.gsub(/^\s+\n/, '')
  end

  def _get_by_self_reference(arg)
    return if arg[:action].to_s =~ /^action_/ && ![:read, nil].include?(arg[:orig_action])
    _get_by_method(arg)
  end

  def _get_by_action_tmpl(arg)
    return nil unless !arg[:recur] && action_tmpl = my[:tmpl][arg[:action]]
    _get_by_tmpl(arg.merge(:action => nil, :sub_action => nil, :recur => true), action_tmpl)
  end

  def _g_default(arg, &block)
    collect_item(arg[:conds] || {}) {|item|
      item_arg = item_arg(arg, item[:id])
      next if item.empty? && ![:create, :update].include?(item_arg[:action])
      block ? block.call(item, item_arg) : item.get(item_arg)
    }.join
  end

  def _g_errors(arg)
    # errors are shown by scalars
  end

  def item_arg(arg, steps)
    Array(steps).inject(arg) {|a, s|
      i = a[s] || {}
      i[:p_action] = a[:action]
      unless i[:action]
        i[:action]     = a[:action]
        i[:sub_action] = a[:sub_action] if a[:sub_action]
      end
      i
    }
  end

  def action_tmpl(arg)
    if summary?(arg) && my[:tmpl][:summary]
      my[:tmpl][:summary]
    elsif action_tmpl = my[:tmpl][arg[:sub_action]] || my[:tmpl][arg[:action]]
      action_tmpl
    elsif [:create, :update, :delete, :login].include? arg[:action]
      my[:tmpl][:form] || my[:tmpl][:index]
    else
      my[:tmpl][:read] || my[:tmpl][:index]
    end
  end

  def summary?(arg)
    [:read, nil].include?(arg[:action]) && !arg[:sub_action]
  end

  def permit_post?(action, val)
    super || val.all? {|id, v|
      if id.is_a? ::Symbol
        true # not a item value
      elsif id =~ Bike::REX::ID_NEW
        permit? :create
      else
        item_action = (v.is_a?(::Hash) && v[:action]) || :update
        item(id) && item(id).permit?(item_action)
      end
    }
  end

  def pending_items
    @item_object.keys.sort.inject({}) {|h, id|
      h[id] = @item_object[id] if @item_object[id].pending?
      h
    }
  end

end
