#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'sofa'

use Rack::ShowExceptions
use Rack::Session::Pool #Cookie
use Rack::Lock

run Sofa.new
