# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Text < Bike::Field

  def initialize(meta = {})
    meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
    super
  end

  def errors
    if (my[:max].to_i > 0) && (val.size > my[:max])
      [_('too long: %{max} characters maximum') % {:max => my[:max]}]
    elsif (my[:min].to_i == 1) && val.empty?
      [_('mandatory')]
    elsif (my[:min].to_i > 0) && (val.size < my[:min])
      [_('too short: %{min} characters minimum') % {:min => my[:min]}]
    else
      []
    end
  end

  private

  def _g_update(arg)
    <<_html.chomp
<span class="#{_g_class arg}"><input type="text" name="#{my[:short_name]}" value="#{Bike::Field.h val}" size="#{my[:size]}" />#{_g_errors arg}</span>
_html
  end
  alias :_g_create :_g_update

  def val_cast(v)
    v.to_s
  end

end
