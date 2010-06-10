# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2010 Akira FUNAI

require 'gettext'

module GetText::LazyParser

  GetText::RGetText.add_parser GetText::LazyParser

  module_function

  def target?(file)
    File.extname(file) == '.rb'
  end

  def parse(file)
    ary = []

    code = ::File.open(file) {|f| f.read }
    s = StringScanner.new code
    until s.eos?
      if (
        s.scan(/_\('([^']+)'\)/)  ||
        s.scan(/_ '([^']+)'/)     ||
        s.scan(/_ ([\w\.]+)/)
      )
        po = GetText::PoMessage.new :normal
        po.msgid = s[1]
        po.sources = ["#{file}:#{_line(s.pos, code)}"]
        ary << po
      elsif (
        s.scan(/n_\(\s*'([^']+)'\s*,\s*'([^']+)'/m)
      )
        po = GetText::PoMessage.new :plural
        po.msgid = s[1]
        po.msgid_plural = s[2]
        po.sources = ["#{file}:#{_line(s.pos, code)}"]
        ary << po
      else
        s.scan /.+?(?=_|n|\z)/m
      end
    end

    ary
  end

  def _line(pos, code)
    code[0...pos].count("\n") + 1
  end

end
