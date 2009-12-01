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

	def test_steps_of
		sofa = Sofa.new

		assert_equal(
			['foo','bar'],
			sofa.instance_eval {
				steps_of '/foo/bar/'
			},
			'Sofa#steps_of should be able to extract item steps from path_info'
		)
		assert_equal(
			['foo','bar'],
			sofa.instance_eval {
				steps_of '/foo/bar/create.html'
			},
			'Sofa#steps_of should ignore the pseudo-filename'
		)
		assert_equal(
			['foo'],
			sofa.instance_eval {
				steps_of '/foo/bar'
			},
			'Sofa#steps_of should ignore the last step without a following slash'
		)
		assert_equal(
			['foo','bar'],
			sofa.instance_eval {
				steps_of '/foo//bar/baz=123/'
			},
			'Sofa#steps_of should distinguish item steps from conds'
		)
	end

	def test_steps_of_with_empty_steps
		sofa = Sofa.new

		assert_equal(
			[],
			sofa.instance_eval {
				steps_of ''
			},
			'Sofa#steps_of should return empty array when there is no item steps'
		)
		assert_equal(
			[],
			sofa.instance_eval {
				steps_of '/'
			},
			'Sofa#steps_of should return empty array when there is no item steps'
		)
		assert_equal(
			[],
			sofa.instance_eval {
				steps_of '/index.html'
			},
			'Sofa#steps_of should return empty array when there is no item steps'
		)
	end

	def test_steps_of_with_cond_d
		sofa = Sofa.new

		assert_equal(
			['foo','bar'],
			sofa.instance_eval {
				steps_of '/foo/bar/2009/'
			},
			'Sofa#steps_of should distinguish item steps from ambiguous conds[:d]'
		)
		assert_equal(
			['foo','bar'],
			sofa.instance_eval {
				steps_of '/foo/bar/1970/'
			},
			'Sofa#steps_of should distinguish item steps from ambiguous conds[:d]'
		)
		assert_equal(
			['foo','bar','3001'],
			sofa.instance_eval {
				steps_of '/foo/bar/3001/'
			},
			'Sofa#steps_of should be patched in the next millennium :-)'
		)
	end

	def test_conds_of
		sofa = Sofa.new

		assert_equal(
			{},
			sofa.instance_eval {
				conds_of '/foo/bar/'
			},
			'Sofa#conds_of should return empty hash when there is no conds'
		)
		assert_equal(
			{
				:baz => '123',
				:qux => '456',
			},
			sofa.instance_eval {
				conds_of '/foo/bar/baz=123/qux=456/'
			},
			'Sofa#conds_of should be able to extract conds from path_info'
		)
		assert_equal(
			{
				:baz => '123',
				:qux => '456',
			},
			sofa.instance_eval {
				conds_of '/foo/bar/baz=123/qux=456/create.html'
			},
			'Sofa#conds_of should ignore the pseudo-filename'
		)
		assert_equal(
			{
				:baz => '1234',
			},
			sofa.instance_eval {
				conds_of '/foo/bar//baz=1234//qux=4567'
			},
			'Sofa#conds_of should ignore the item steps and the last step without a slash'
		)
	end

	def test_conds_of_with_empty_conds
		sofa = Sofa.new

		assert_equal(
			{},
			sofa.instance_eval {
				conds_of ''
			},
			'Sofa#conds_of should return empty hash when there is no conds'
		)
		assert_equal(
			{},
			sofa.instance_eval {
				conds_of '/'
			},
			'Sofa#conds_of should return empty hash when there is no conds'
		)
		assert_equal(
			{},
			sofa.instance_eval {
				conds_of '/index.html'
			},
			'Sofa#conds_of should return empty hash when there is no conds'
		)
	end

	def test_conds_of_with_cond_d
		sofa = Sofa.new

		assert_equal(
			{
				:d   => '200911',
				:baz => '1234',
				:qux => '4567',
			},
			sofa.instance_eval {
				conds_of '/foo/bar/200911/baz=1234/qux=4567/'
			},
			'Sofa#conds_of should be able to distinguish ambiguous cond[:d]'
		)
		assert_equal(
			{
				:baz => '1234',
				:qux => '4567',
			},
			sofa.instance_eval {
				conds_of '/foo/bar/20091129_0001/baz=1234/qux=4567/'
			},
			'Sofa#conds_of should ignore the full-formatted id'
		)
	end

	def test_action_of
		sofa = Sofa.new

		assert_equal(
			:create,
			sofa.instance_eval {
				action_of '/foo/bar/create.html'
			},
			'Sofa#action_of should extract the action from path_info'
		)

		assert_nil(
			sofa.instance_eval {
				action_of '/foo/bar/index.html'
			},
			'Sofa#action_of should return nil if the pseudo-filename is index.*'
		)
		assert_nil(
			sofa.instance_eval {
				action_of '/foo/bar/'
			},
			'Sofa#action_of should return nil if no pseudo-filename is given'
		)
	end

	def test_base_of
		sofa = Sofa.new

		sd = sofa.instance_eval {
			base_of '/foo/bar/main/index.html'
		}
		assert_instance_of(
			Sofa::Set::Dynamic,
			sd,
			'Sofa#base_of should return a set_dynamic'
		)
		assert_equal(
			'-foo-bar-main',
			sd[:full_name],
			'Sofa#base_of should return a set_dynamic at the bottom of the given steps'
		)

		sd = sofa.instance_eval {
			base_of '/foo/bar/index.html'
		}
		assert_instance_of(
			Sofa::Set::Dynamic,
			sd,
			'Sofa#base_of should return a set_dynamic'
		)
		assert_equal(
			'-foo-bar-main',
			sd[:full_name],
			"Sofa#base_of should return the item('main') if the given steps point at a folder"
		)

		sd = sofa.instance_eval {
			base_of '/foo/bar/20091120_0001/files/index.html'
		}
		assert_instance_of(
			Sofa::Set::Dynamic,
			sd,
			'Sofa#base_of should return a set_dynamic'
		)
		assert_equal(
			'-foo-bar-main-20091120_0001-files',
			sd[:full_name],
			"Sofa#base_of should be able to dive into any depth from the folder"
		)

		sd = sofa.instance_eval {
			base_of '/foo/bar/20091120_0002/files/index.html'
		}
		assert_nil(
			sd,
			'Sofa#base_of should return nil if there is no set_dynamic at the steps'
		)
	end

	def test_params_from_request
		sofa = Sofa.new

		env = Rack::MockRequest.env_for(
			'http://example.com/foo/bar/main/qux=456/wink.html?acorn=round',
			{
				:script_name => '',
				:input       => 'coax=true&some-doors=open',
			}
		)
		req = Rack::Request.new env
		params = sofa.instance_eval {
			params_from_request req
		}
		assert_equal(
			{
				'main'  => {
					:conds  => {:qux => '456'},
					:action => :wink,
				},
				'acorn' => 'round',
				'coax'  => 'true',
				'some'  => {'doors' => 'open'},
			},
			params,
			'Sofa#params_from_request should build params from req.path_info and req.params'
		)

		env = Rack::MockRequest.env_for(
			'http://example.com/foo/bar/qux=456/index.html?acorn=round',
			{
				:script_name => '',
				:input       => 'coax=true&some-doors=open',
			}
		)
		req = Rack::Request.new env
		params = sofa.instance_eval {
			params_from_request req
		}
		assert_equal(
			{
				'main'  => {
					:conds  => {:qux => '456'},
					:action => nil,
				},
				'acorn' => 'round',
				'coax'  => 'true',
				'some'  => {'doors' => 'open'},
			},
			params,
			'Sofa#params_from_request should build params from req.path_info and req.params'
		)

		env = Rack::MockRequest.env_for(
			'http://example.com/foo/bar/20091120_0001/files/qux=456/index.html?acorn=round',
			{
				:script_name => '',
				:input       => 'coax=true&some-doors=open',
			}
		)
		req = Rack::Request.new env
		params = sofa.instance_eval {
			params_from_request req
		}
		assert_equal(
			{
				'main'  => {
					'20091120_0001' => {
						'files' => {
							:conds  => {:qux => '456'}, 
							:action => nil,
						},
					},
				},
				'acorn' => 'round',
				'coax'  => 'true',
				'some'  => {'doors' => 'open'},
			},
			params,
			'Sofa#params_from_request should attach the params from path_info to the base SD'
		)

		env = Rack::MockRequest.env_for(
			'http://example.com/foo/bar/qux=456/index.html?acorn=round',
			{
				:script_name => '',
				:input       => 'some-doors=open&some.action-open=submit',
			}
		)
		req = Rack::Request.new env
		params = sofa.instance_eval {
			params_from_request req
		}
		assert_equal(
			{
				'main'  => {
					:conds  => {:qux => '456'},
					:action => nil,
				},
				'acorn' => 'round',
				'some'  => {'doors' => 'open',:action => :open},
			},
			params,
			'Sofa#params_from_request should build params from req.path_info and req.params'
		)
	end

	def test_current
		Sofa.current[:foo] = 'main foo' 
		main_current = Sofa.current

		t = Thread.new {
			assert_not_equal(
				main_current,
				Sofa.current,
				'Sofa.current should be unique per a thread'
			)
			assert_not_equal(
				'main foo',
				Sofa.current[:foo],
				'Sofa.current should be unique per a thread'
			)
			Sofa.current[:foo] = 'child foo' 
		}
		t.join

		assert_equal(
			'main foo',
			Sofa.current[:foo],
			'Sofa.current should be unique per a thread'
		)
	end

end
