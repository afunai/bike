# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Dynamic

  private

  def _g_done(arg)
    (_get_by_action_tmpl(arg) || <<_html.chomp) if arg[:orig_action] == :done
<div class="done">#{_ 'done.'}</div>
_html
  end

end
