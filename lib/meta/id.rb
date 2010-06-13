# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Meta::Id < Runo::Field

  # not include Runo::Meta as this is SHORT_ID, not a full id.

  def initialize(meta = {})
    meta[:size] = $&.to_i if meta[:tokens] && meta[:tokens].first =~ /^\d+$/
    super
  end

  def errors
    if (my[:max].to_i > 0) && (val.size > my[:max])
      [_('too long: %{max} characters maximum') % {:max => my[:max]}]
    elsif (my[:min].to_i == 1) && val.empty?
      [_ 'mandatory']
    elsif (my[:min].to_i > 0) && (val.size < my[:min])
      [_('too short: %{min} characters minimum') % {:min => my[:min]}]
    elsif val !~ /\A#{Runo::REX::ID_SHORT}\z/
      [_('malformatted id')]
    elsif (
      my[:parent] &&
      my[:parent][:id] !~ /00000000_#{val}$/ &&
      my[:parent][:parent].is_a?(Runo::Set::Dynamic) &&
      my[:parent][:parent].item(val)
    )
      [_('duplicate id: %{id}') % {:id => val}]
    else
      []
    end
  end

  private

  def _g_create(arg)
    new_id? ? <<_html.chomp : _g_default(arg)
<span class="#{_g_class arg}"><input type="text" name="#{my[:short_name]}" value="#{Runo::Field.h val}" size="#{my[:size]}" />#{_g_errors arg}</span>
_html
  end
  alias :_g_update :_g_create

  def new_id?
    find_ancestor {|i| i[:id] =~ Runo::REX::ID_NEW } ? true : false
  end

  def _post(action, v)
    if action == :load || ([:create, :update].include?(action) && new_id?)
      @val = val_cast v
    end
  end

  def val_cast(v)
    v.to_s
  end

end
