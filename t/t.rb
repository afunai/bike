#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'test/unit'
require 'rubygems'
require 'mocha'
require 'rack'

t_dir = ::File.dirname __FILE__

$LOAD_PATH.unshift t_dir
$LOAD_PATH.unshift(::File.expand_path('../lib', t_dir))
require 'bike'

Bike.config(
  'skin_dir' => './t/skin',
  'storage'  => {
    'default' => 'File',
    'File'    => {'data_dir' => './t/data'},
    'Sequel'  => {'uri'      => 'sqlite:/'},
  }
)

Bike::I18n.bindtextdomain('index', ::File.join(t_dir, 'locale'))
