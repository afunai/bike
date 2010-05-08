#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'test/unit'
require 'rubygems'
require 'mocha'

require 'sofa'

Sofa.instance_eval { @config = YAML.load_file './t.yaml' }
Sofa::I18n.bindtextdomain('index','./t/locale')

result = Test::Unit::AutoRunner.run(true,'t/')
