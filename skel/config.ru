#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

require 'rubygems'

$LOAD_PATH.unshift(::File.expand_path('../lib',::File.dirname(__FILE__)))
require 'runo'

use Rack::ShowExceptions
use Rack::Session::Pool #Cookie
use Rack::Lock

::Dir.chdir ::File.dirname(__FILE__)

Runo.config(
  'skin_dir' => './skin',
  'storage'  => {
    'default' => 'File',
    'File'    => {'data_dir' => './data'},
    'Sequel'  => {'uri'      => 'sqlite:/'},
  }
)

run Runo.new
