# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Runo::Select < Runo::Field

  def initialize(meta = {})
    meta[:mandatory] = meta[:tokens] && meta[:tokens].include?('mandatory')
    meta[:options] ||= meta[:max] && (meta[:min].to_i..meta[:max]).collect {|i| i.to_s }
    super
  end

  def errors
    if my[:mandatory] && val.empty?
      [_('mandatory')]
    elsif my[:options].include?(val) || val.empty?
      []
    else
      [_('no such option')]
    end
  end

  private

  def _g_update(arg)
    options = my[:options].collect {|opt|
      selected = (opt == val) ? ' selected' : ''
      "    <option#{selected}>#{Runo::Field.h opt}</option>\n"
    }.join
    unless my[:mandatory] && my[:options].include?(val)
      options = "    <option value=\"\">#{_ 'please select'}</option>\n#{options}"
    end
    <<_html
<span class="#{_g_class arg}">
  <select name="#{my[:short_name]}">
#{options}  </select>
#{_g_errors arg}</span>
_html
  end
  alias :_g_create :_g_update

  def val_cast(v)
    v.to_s
  end

end
