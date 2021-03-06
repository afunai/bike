# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Checkbox < Bike::Field

  def initialize(meta = {})
    if meta[:tokens]
      meta[:options] ||= meta[:tokens] - ['mandatory']
      meta[:options] = ['_on'] if meta[:options].empty?
      meta[:mandatory] = meta[:tokens].include?('mandatory') && Array(meta[:options]).size > 1
    end
    if meta[:options].size == 1 && meta[:default] =~ /^(on|true|yes)$/i
      meta[:default] = meta[:options].first
    end
    super
  end

  def errors
    if val.empty?
      my[:mandatory] ? [_('mandatory')] : []
    else
      (val - my[:options]).empty? ? [] : [_('no such option')]
    end
  end

  private

  def _g_default(arg)
    val.join ', '
  end

  def _g_update(arg)
    if my[:options] == ['_on']
      checked = (val.include? '_on') ? ' checked' : ''
      <<_html
<span class="#{_g_class arg}">
  <input type="hidden" name="#{my[:short_name]}[]" value="" />
  <input type="checkbox" name="#{my[:short_name]}[]" value="_on" #{checked}/>
#{_g_errors arg}</span>
_html
    else
      options = my[:options].collect {|opt|
        checked = (val.include? opt) ? ' checked' : ''
        <<_html
  <span class="item">
    <input type="checkbox" id="checkbox_#{my[:short_name]}-#{opt}" name="#{my[:short_name]}[]" value="#{opt}"#{checked} />
    <label for="checkbox_#{my[:short_name]}-#{opt}">#{opt}</label>
  </span>
_html
      }.join
      <<_html
<span class="#{_g_class arg}">
  <input type="hidden" name="#{my[:short_name]}[]" value="" />
#{options}#{_g_errors arg}</span>
_html
    end
  end
  alias :_g_create :_g_update

  def val_cast(v)
    Array(v).collect {|i|
      i.to_s unless i.to_s.empty?
    }.compact
  end

end
