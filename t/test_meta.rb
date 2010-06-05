# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Meta < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_owner
		ss = Runo::Set::Static.new(
			:item => {
				'_owner' => {:klass => 'meta-owner'},
			}
		)
		assert_instance_of(
			Runo::Meta::Owner,
			ss.item('_owner'),
			"Set::Static#item('_owner') should be an instance of the meta field"
		)

		ss.item('_owner').load 'frank'
		assert_equal(
			'frank',
			ss.val('_owner'),
			'Meta::Owner#load should work like normal fields'
		)
		assert_equal(
			'frank',
			ss[:owner],
			'Meta::Owner#load should update the [:owner] of the parent set'
		)

		ss.item('_owner').update 'carl'
		assert_equal(
			'frank',
			ss.val('_owner'),
			'Meta::Owner should not be updated'
		)
		assert(
			!ss.item('_owner').pending?,
			'Meta::Owner should not be updated'
		)
		assert_equal(
			'frank',
			ss[:owner],
			'Meta::Owner should not be updated'
		)
	end

end
