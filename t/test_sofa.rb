# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Sofa < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_session
		assert(
			Sofa.session.respond_to?(:[]),
			'Sofa.session should be a Session or Hash'
		)
	end

	def test_client
		Sofa.client = nil
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa.client should return nobody before login'
		)

		Sofa.client = 'frank'
		assert_equal(
			'frank',
			Sofa.client,
			'Sofa.client should return the user who logged in'
		)

		Sofa.client = nil
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa.client should return nobody after logout'
		)
	end

	def test_rebuild_params
		sofa = Sofa.new

		hash = sofa.instance_eval {
			rebuild_params(
				'.action' => 'update'
			)
		}
		assert_equal(
			{:action => :update},
			hash,
			'Sofa#rebuild_params should be able to rebuild special symbols'
		)

		hash = sofa.instance_eval {
			rebuild_params(
				'.action-update' => 'submit'
			)
		}
		assert_equal(
			{:action => :update},
			hash,
			'Sofa#rebuild_params should be able to rebuild special symbols'
		)

		hash = sofa.instance_eval {
			rebuild_params(
				'noo'               => 'what?',
				'noo.action-update' => 'submit',
				'noo.conds-id'      => '4567'
			)
		}
		assert_equal(
			{
				'noo' => {
					:self   => 'what?',
					:action => :update,
					:conds  => {:id => '4567'},
				},
			},
			hash,
			'Sofa#rebuild_params should rebuild both the special symbols and regular items'
		)

		hash = sofa.instance_eval {
			rebuild_params(
				'moo.conds-p'                   => '9',
				'moo-4567-addr.conds-zip-upper' => '110'
			)
		}
		assert_equal(
			{
				'moo' => {
					:conds => {:p => '9'},
					'4567' => {
						'addr' => {
							:conds => {:'zip-upper' => '110'},
						},
					},
				},
			},
			hash,
			'Sofa#rebuild_params should be able to rebuild any combination of symbols and items'
		)

		hash = sofa.instance_eval {
			rebuild_params(
				'foo-bar.conds-id'  => '1234',
				'foo-bar.conds-p'   => ['42'],
				'foo-bar.action'    => 'update',
				'foo-baz'           => ['boo','bee'],
				'foo'               => 'oops',
				'qux.action-create' => 'submit'
			)
		}
		assert_equal(
			{
				'foo' => {
					:self => 'oops',
					'bar' => {
						:action => :update,
						:conds  => {
							:id => '1234',
							:p  => ['42'],
						},
					},
					'baz' => ['boo','bee'],
				},
				'qux' => {
					:action => :create,
				},
			},
			hash,
			'Sofa#rebuild_params should be able to rebuild any combination of symbols and items'
		)
	end

end
