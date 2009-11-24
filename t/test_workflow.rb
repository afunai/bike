# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Workflow < Test::Unit::TestCase

	class Sofa::Workflow::Foo < Sofa::Workflow
		PERM = {
			:create => 0b1100,
			:read   => 0b1111,
			:update => 0b1010,
			:delete => 0b1100,
		}
	end

	def setup
	end

	def teardown
	end

	def test_instance
		sd = Sofa::Set::Dynamic.new
		assert_instance_of(
			Sofa::Workflow,
			Sofa::Workflow.instance(sd),
			'Sofa::Workflow.instance should return a Workflow instance if sd[:workflow] is nil'
		)
		sd = Sofa::Set::Static::Folder.root.item('foo','main')
		assert_instance_of(
			Sofa::Workflow::Blog,
			Sofa::Workflow.instance(sd),
			'Sofa::Workflow.instance should return a instance according to sd[:workflow]'
		)

		assert_equal(
			sd,
			Sofa::Workflow.instance(sd).sd,
			'Sofa::Workflow.instance should set @sd'
		)
	end

	def test_wf_permit_guest?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_GUEST,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_GUEST,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_GUEST,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_GUEST,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test_wf_permit_owner?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_OWNER,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_OWNER,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_OWNER,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_OWNER,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test_wf_permit_group?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_GROUP,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_GROUP,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_GROUP,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_GROUP,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test_wf_permit_admin?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_ADMIN,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_ADMIN,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_ADMIN,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(Sofa::Workflow::ROLE_ADMIN,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test_wf_permit_abnormal_action?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { permit?(Sofa::Workflow::ROLE_ADMIN,:'non-exist') },
			'Set::Workflow#permit? should always return false for non-exist actions'
		)
	end

	def test_permit_nobody?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = nil
		assert(
			!sd.permit?(:create),
			"'nobody' should not create"
		)
		assert(
			sd.item('20091120_0001').permit?(:read),
			"'nobody' should be able to read the item"
		)
		assert(
			!sd.item('20091120_0001').permit?(:update),
			"'nobody' should not update carl's item"
		)
		assert(
			!sd.item('20091120_0001').permit?(:delete),
			"'nobody' should not delete carl's item"
		)
	end

	def test_permit_don?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'don' # don belongs to the group of foo/bar/
		assert(
			sd.permit?(:create),
			'don should be able to create'
		)
		assert(
			sd.item('20091120_0001').permit?(:read),
			'don should be able to read the item'
		)
		assert(
			sd.item('20091120_0001').permit?(:update),
			"don should be able to update carl's item"
		)
		assert(
			!sd.item('20091120_0001').permit?(:delete),
			"don should not delete carl's item"
		)
	end

	def test_permit_carl?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'carl' # carl belongs to the group of foo/bar/, and the owner of the item #0001
		assert(
			sd.permit?(:create),
			'carl should be able to create'
		)
		assert(
			sd.item('20091120_0001').permit?(:read),
			'carl should be able to read the item'
		)
		assert(
			sd.item('20091120_0001').permit?(:update),
			"carl should be able to update his own item"
		)
		assert(
			sd.item('20091120_0001').permit?(:delete),
			"carl should be able to delete his own item"
		)
	end

	def test_permit_frank?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'frank' # frank is an admin of foo/bar/
		assert(
			sd.permit?(:create),
			'frank should be able to create'
		)
		assert(
			sd.item('20091120_0001').permit?(:read),
			'frank should be able to read the item'
		)
		assert(
			sd.item('20091120_0001').permit?(:update),
			"frank should be able to update his own item"
		)
		assert(
			sd.item('20091120_0001').permit?(:delete),
			"frank should be able to delete his own item"
		)
	end

	def test_permit_abnormal_action?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'frank'
		assert(
			!sd.permit?(:'****'),
			'frank should not **** on the stage'
		)
	end

	class Sofa::Workflow::Test_Default_Action < Sofa::Workflow
		PERM = {
			:create => 0b1100,
			:read   => 0b1000,
			:update => 0b1110,
			:foo    => 0b1111,
		}
	end
	def test_default_action
		sd = Sofa::Set::Dynamic.new(:group => ['roy'])
		sd.instance_eval { @workflow = Sofa::Workflow::Test_Default_Action.new sd }
		def sd.meta_admins
			['frank']
		end
		sd.load(
			'20091122_0001' => {'_owner' => 'carl'},
			'20091122_0002' => {'_owner' => 'frank'}
		)

		Sofa.client = nil
		assert_equal(
			:foo,
			sd.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)

		Sofa.client = 'carl' # carl is not the member of the group
		assert_equal(
			:foo,
			sd.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)
		assert_equal(
			:update,
			sd.item('20091122_0001').default_action,
			'Workflow#default_action should see the given conds'
		)

		Sofa.client = 'roy' # roy belongs to the group
		assert_equal(
			:create,
			sd.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)

		Sofa.client = 'frank' # frank is the admin
		assert_equal(
			:read,
			sd.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)
	end

end
