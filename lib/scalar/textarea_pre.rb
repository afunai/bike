# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

require 'rack/utils'

class Runo::Textarea::Pre < Runo::Textarea

  def _g_default(arg)
    '<pre>' + Runo::Field.h(val) + '</pre>'
  end

end
