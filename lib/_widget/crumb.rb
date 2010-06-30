# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Static::Folder

  private

  def _g_crumb(arg)
    <<_html
<div class="crumb">
#{_crumb}</div>
_html
  end

  def _crumb
    crumb = <<_html
  <a href="#{Runo.uri}#{my[:dir]}/">#{my[:label] || my[:id]}</a>
_html
    my[:parent] ? [my[:parent].send(:_crumb), crumb].join("  &raquo;\n") : crumb
  end

end
