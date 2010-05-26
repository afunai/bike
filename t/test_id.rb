# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class TC_Id < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar('$(foo meta-id 3 1..5)') {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta
	end

	def teardown
	end

	def test_meta
		assert_equal(
			3,
			@f[:size],
			'Meta::Id#initialize should set :size from the token'
		)
		assert_equal(
			1,
			@f[:min],
			'Meta::Id#initialize should set :min from the range token'
		)
		assert_equal(
			5,
			@f[:max],
			'Meta::Id#initialize should set :max from the range token'
		)
	end

	def test_val_cast
		assert_equal(
			'',
			@f.val,
			'Meta::Id#val_cast should cast the given val to String'
		)

		@f.load 123
		assert_equal(
			'123',
			@f.val,
			'Meta::Id#val_cast should cast the given val to String'
		)
	end

	def test_new_id?
		@f[:parent] = Sofa::Set::Static.new(:id => '20100526_0001')
		assert_equal(
			false,
			@f.send(:new_id?),
			'Meta::Id#new_id? should return whether the ancestors is new or not'
		)

		@f[:parent] = Sofa::Set::Static.new(:id => '_001')
		assert_equal(
			true,
			@f.send(:new_id?),
			'Meta::Id#new_id? should return whether the ancestors is new or not'
		)
	end

	def test_get
		assert_equal(
			'<input type="text" name="" value="" size="3" class="meta-id" />',
			@f.get(:action => :create),
			'Meta::Id#get should return proper string'
		)

		@f.load 'bar'
		assert_equal(
			'bar',
			@f.get,
			'Meta::Id#get should return proper string'
		)
		assert_equal(
			'bar',
			@f.get(:action => :update),
			'Meta::Id#get should not be updated'
		)

		@f.load '<bar>'
		assert_equal(
			'&lt;bar&gt;',
			@f.get,
			'Meta::Id#get should escape the special characters'
		)
	end

	def test_post
		@f.create 'frank'
		assert_equal(
			'frank',
			@f.val,
			'Meta::Id#post should create like a normal field'
		)

		@f.update 'bobby'
		assert_equal(
			'frank',
			@f.val,
			'Meta::Id#post should not update the current val'
		)

		@f.create 'bobby'
		assert_equal(
			'frank',
			@f.val,
			'Meta::Id#post should not re-create the current val'
		)
	end

	def test_errors
		@f.load '<a'
		assert_equal(
			['malformatted id'],
			@f.errors,
			'Meta::Id#errors should return the errors of the current val'
		)

		@f.load '123a'
		assert_equal(
			['malformatted id'],
			@f.errors,
			'Meta::Id#errors should return the errors of the current val'
		)

		@f.load 'abcdefghijk'
		assert_equal(
			['too long: 5 characters maximum'],
			@f.errors,
			'Meta::Id#errors should return the errors of the current val'
		)

		@f.load 'frank'
		assert_equal(
			[],
			@f.errors,
			'Meta::Id#errors should return an empty array if there is no error'
		)
	end

end
