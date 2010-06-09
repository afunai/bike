#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

$LOAD_PATH.unshift(::File.expand_path('../lib',::File.dirname(__FILE__)))
require 'runo'

use Rack::ShowExceptions
use Rack::Session::Pool #Cookie
use Rack::Lock

run Runo.new
