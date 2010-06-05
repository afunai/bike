#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'test/unit'
require 'rubygems'
require 'mocha'

require 'runo'

Runo.instance_eval { @config = YAML.load_file './t.yaml' }
Runo::I18n.bindtextdomain('index','./t/locale')

result = Test::Unit::AutoRunner.run(true,'t/')
