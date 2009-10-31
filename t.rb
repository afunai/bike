#!/usr/bin/env ruby
# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'test/unit'
require 'rubygems'
require 'mocha'

result = Test::Unit::AutoRunner.run(true,'t/')
