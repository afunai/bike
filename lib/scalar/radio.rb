# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Radio < Bike::Field

  def initialize(meta = {})
    meta[:mandatory] = meta[:tokens] && meta[:tokens].include?('mandatory')
    meta[:options] ||= meta[:max] && (meta[:min].to_i..meta[:max]).collect {|i| i.to_s }
    super
  end

  def errors
    if val.empty?
      my[:mandatory] ? [_('mandatory')] : []
    else
      my[:options].include?(val) ? [] : [_('no such option')]
    end
  end

  private

  def _g_update(arg)
    options = my[:options].collect {|opt|
      checked = (opt == val) ? ' checked' : ''
      h_opt = Bike::Field.h opt
      <<_html
  <span class="item">
    <input type="radio" id="radio_#{my[:short_name]}-#{h_opt}" name="#{my[:short_name]}" value="#{h_opt}"#{checked} />
    <label for="radio_#{my[:short_name]}-#{h_opt}">#{h_opt}</label>
  </span>
_html
    }.join
    <<_html
<span class="#{_g_class arg}">
  <input type="hidden" name="#{my[:short_name]}" value="" />
#{options}#{_g_errors arg}</span>
_html
  end
  alias :_g_create :_g_update

  def val_cast(v)
    v.to_s
  end

end
