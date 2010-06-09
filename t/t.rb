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
$LOAD_PATH.unshift(::File.expand_path('../lib',t_dir))
require 'runo'

Runo.instance_eval { @config = YAML.load_file ::File.join(t_dir,'t.yaml') }
Runo::I18n.bindtextdomain('index',::File.join(t_dir,'locale'))
