# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Textarea < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar('$(foo textarea 76*8 1..1024)') {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta
	end

	def teardown
	end

	def test_meta
		assert_equal(
			76,
			@f[:width],
			'Textarea#initialize should set :width from the dimension token'
		)
		assert_equal(
			8,
			@f[:height],
			'Textarea#initialize should set :height from the dimension token'
		)
		assert_equal(
			1,
			@f[:min],
			'Text#initialize should set :min from the range token'
		)
		assert_equal(
			1024,
			@f[:max],
			'Text#initialize should set :max from the range token'
		)
	end

	def test_val_cast
		assert_equal(
			'',
			@f.val,
			'Textarea#val_cast should cast the given val to String'
		)

		@f.load 123
		assert_equal(
			'123',
			@f.val,
			'Textarea#val_cast should cast the given val to String'
		)
	end

	def test_get
		@f.load 'bar'
		assert_equal(
			'bar',
			@f.get,
			'Textarea#get should return proper string'
		)
		assert_equal(
			'<textarea name="" cols="76" rows="8" class="">bar</textarea>',
			@f.get(:action => :update),
			'Textarea#get should return proper string'
		)

		@f.load '<bar>'
		assert_equal(
			'&lt;bar&gt;',
			@f.get,
			'Textarea#get should escape the special characters'
		)
	end

end
