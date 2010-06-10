# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Runo::Password < Runo::Field

  def initialize(meta = {})
    meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].find {|t| t =~ /^\d+$/ }
    super
  end

  def errors
    if @size.nil?
      []
    elsif (my[:max].to_i > 0) && (@size > my[:max])
      [_('too long: %{max} characters maximum') % {:max => my[:max]}]
    elsif (my[:min].to_i == 1) && (@size == 0)
      [_ 'mandatory']
    elsif (my[:min].to_i > 0) && (@size < my[:min])
      [_('too short: %{min} characters minimum') % {:min => my[:min]}]
    else
      []
    end
  end

  private

  def _g_default(arg)
    '*' * (@size || 5)
  end

  def _g_update(arg)
    <<_html.chomp
<input type="password" name="#{my[:short_name]}" value="" size="#{my[:size]}" class="#{_g_class arg}" />#{_g_errors arg}
_html
  end
  alias :_g_create :_g_update

  def _post(action, v)
    case action
      when :load
        @size = nil
        @val = v
      when :create, :update
        if v.is_a?(::String) && !v.empty?
          salt = ('a'..'z').to_a[rand 26] + ('a'..'z').to_a[rand 26]
          @size = v.size
          @val = v.crypt salt
        elsif @val.nil?
          @size = 0
        else
          # no action: keep current @val
        end
    end
  end

end
