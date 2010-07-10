# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'time'

class Runo::Meta::Timestamp < Runo::Field

  include Runo::Meta

  REX_DATE = /\A(\d+).(\d+).(\d+)(?:[T\s](\d+):(\d+)(?::(\d+))?)?\z/

  def initialize(meta = {})
    meta[:size]       = $&.to_i if meta[:tokens] && meta[:tokens].find {|t| t =~ /^\d+$/ }
    meta[:can_edit]   = true if Array(meta[:tokens]).include? 'can_edit'
    meta[:can_update] = true if Array(meta[:tokens]).include? 'can_update'
    super
  end

  def errors
    if @date_str.nil?
      []
    elsif @date_str =~ REX_DATE
      (Time.local($1, $2, $3, $4, $5, $6) rescue nil) ? [] : ['out of range']
    else
      ['wrong format']
    end
  end

  private

  def _g_default(arg)
    _date val['published']
  end
  alias :_g_published :_g_default

  def _g_rfc2822(arg)
    val['published'].rfc2822
  end

  def _g_created(arg)
    _date val['created']
  end

  def _g_updated(arg)
    _date val['updated']
  end

  def _date(time)
    time.is_a?(::Time) ? time.strftime(_('%Y-%m-%dT%H:%M:%S')) : 'n/a'
  end

  def _g_create(arg)
    <<_html.chomp if my[:can_edit]
<span class="#{_g_class arg}"><input type="text" name="#{my[:short_name]}" value="" size="#{my[:size]}" /></span>
_html
  end

  def _g_update(arg)
    if my[:can_edit]
      v = @date_str
      v ||= val['published'].is_a?(::Time) ? val['published'].strftime('%Y-%m-%d %H:%M:%S') : ''
      <<_html.chomp
<span class="#{_g_class arg}"><input type="text" name="#{my[:short_name]}" value="#{Runo::Field.h v}" size="#{my[:size]}" />#{_g_errors arg}</span>
_html
    elsif my[:can_update] && !find_ancestor {|f| f[:id] =~ Runo::REX::ID_NEW }
      <<_html
<span class="#{_g_class arg}">
  <input type="checkbox" id="timestamp_#{my[:short_name]}" name="#{my[:short_name]}" value="true" />
  <label for="timestamp_#{my[:short_name]}">#{_ 'update the timestamp'}</label>
#{_g_errors arg}</span>
_html
    end
  end

  def _post(action, v)
    case action
      when :load
        @val = val_cast v
      when :create
        now = Time.now
        @val = {
          'created'   => now,
          'updated'   => now,
          'published' => now,
        }
        if my[:can_edit] && v['published'].is_a?(::Time)
          @val['published'] = v['published']
        else
          nil # do not set @action
        end
      when :update
        @val['updated'] = Time.now
        if my[:can_edit] && v['published'].is_a?(::Time)
          @val['published'] = v['published']
        elsif my[:can_update] && v['published'] == :same_as_updated
          @val['published'] = @val['updated']
        else
          nil # do not set @action
        end
    end
  end

  def val_cast(v)
    if v.is_a? ::Hash
      v
    elsif v == 'true'
      {'published' => :same_as_updated}
    elsif v.is_a?(::String) && !v.empty?
      @date_str = v
      (v =~ REX_DATE && t = (Time.local($1, $2, $3, $4, $5, $6) rescue nil)) ? {'published' => t} : {}
    else
      {}
    end
  end

end
