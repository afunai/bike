# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

require 'rack/utils'

class Bike::Textarea::Pre < Bike::Textarea

  def _g_default(arg)
    '<pre>' + Bike::Field.h(val) + '</pre>'
  end

end
