#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'runo'

use Rack::ShowExceptions
use Rack::Session::Pool #Cookie
use Rack::Lock

run Runo.new
