# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Workflow < Test::Unit::TestCase

	class Sofa::Workflow::Foo < Sofa::Workflow
		PERM = {
			:create => 'oo--',
			:read   => 'oooo',
			:update => 'o-o-',
			:delete => 'oo--',
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

	def testpermit_guest?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { permit?(:guest,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:guest,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(:guest,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(:guest,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def testpermit_owner?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { permit?(:owner,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:owner,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:owner,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(:owner,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def testpermit_group?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			wf.instance_eval { permit?(:group,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:group,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { permit?(:group,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:group,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def testpermit_admin?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			wf.instance_eval { permit?(:admin,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:admin,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:admin,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { permit?(:admin,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def testpermit_abnormal_role?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { permit?(:'non-exist',:read) },
			'Set::Workflow#permit? should always return false for non-exist roles'
		)
		assert(
			!wf.instance_eval { permit?(:admin,:'non-exist') },
			'Set::Workflow#permit? should always return false for non-exist actions'
		)
	end

	def testpermit_nobody_get?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = nil
		assert(
			!sd.workflow.permit_get?(:action => :create),
			"'nobody' should not get.create"
		)
		assert(
			sd.workflow.permit_get?(:action => :read,:conds => {:id => '20091120_0001'}),
			"'nobody' should be able to get.read the item"
		)
		assert(
			!sd.workflow.permit_get?(:action => :update,:conds => {:id => '20091120_0001'}),
			"'nobody' should not get.update carl's item"
		)
		assert(
			!sd.workflow.permit_get?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"'nobody' should not get.delete carl's item"
		)

		assert(
			!sd.workflow.permit_get?(:action => :update,:conds => {:id => 'non-existent'}),
			"'nobody' should not get.update a non-existent item"
		)
	end

	def testpermit_nobody_post?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = nil
		assert(
			!sd.workflow.permit_post?('_1234' => {'name' => 'foo'}),
			"'nobody' should not post.create"
		)
		assert(
			!sd.workflow.permit_post?('20091120_0001' => {'name' => 'foo'}),
			"'nobody' should not post.update carl's item"
		)
		assert(
			!sd.workflow.permit_post?('20091120_0001' => {'_action' => 'delete'}),
			"'nobody' should not post.delete carl's item"
		)

		assert(
			!sd.workflow.permit_post?('non-existent' => {'name' => 'foo'}),
			"'nobody' should not post.update a non-existent item"
		)
	end

	def testpermit_don_get?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'don' # don belongs to the group of foo/bar/
		assert(
			sd.workflow.permit_get?(:action => :create),
			'don should be able to get.create'
		)
		assert(
			sd.workflow.permit_get?(:action => :read,:conds => {:id => '20091120_0001'}),
			'don should be able to get.read the item'
		)
		assert(
			sd.workflow.permit_get?(:action => :update,:conds => {:id => '20091120_0001'}),
			"don should be able to get.update carl's item"
		)
		assert(
			!sd.workflow.permit_get?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"don should not get.delete carl's item"
		)
	end

	def testpermit_don_post?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'don' # don belongs to the group of foo/bar/
		assert(
			sd.workflow.permit_post?('_1234' => {'name' => 'foo'}),
			'don should be able to post.create'
		)
		assert(
			sd.workflow.permit_post?('20091120_0001' => {'name' => 'foo'}),
			"don should be able to post.update carl's item"
		)
		assert(
			!sd.workflow.permit_post?('20091120_0001' => {'_action' => 'delete'}),
			"don should not post.delete carl's item"
		)
	end

	def testpermit_carl_get?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'carl' # carl belongs to the group of foo/bar/, and the owner of the item #0001
		assert(
			sd.workflow.permit_get?(:action => :create),
			'carl should be able to get.create'
		)
		assert(
			sd.workflow.permit_get?(:action => :read,:conds => {:id => '20091120_0001'}),
			'carl should be able to get.read the item'
		)
		assert(
			sd.workflow.permit_get?(:action => :update,:conds => {:id => '20091120_0001'}),
			"carl should be able to get.update his own item"
		)
		assert(
			sd.workflow.permit_get?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"carl should be able to get.delete his own item"
		)
	end

	def testpermit_carl_post?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'carl' # carl belongs to the group of foo/bar/, and the owner of the item #0001
		assert(
			sd.workflow.permit_post?('_1234' => {'name' => 'foo'}),
			'carl should be able to post.create'
		)
		assert(
			sd.workflow.permit_post?('20091120_0001' => {'name' => 'foo'}),
			"carl should be able to post.update his own item"
		)
		assert(
			sd.workflow.permit_post?('20091120_0001' => {'_action' => 'delete'}),
			"carl should be able to post.delete his own item"
		)
	end

	def testpermit_frank_get?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'frank' # frank is an admin of foo/bar/
		assert(
			sd.workflow.permit_get?(:action => :create),
			'frank should be able to get.create'
		)
		assert(
			sd.workflow.permit_get?(:action => :read,:conds => {:id => '20091120_0001'}),
			'frank should be able to get.read the item'
		)
		assert(
			sd.workflow.permit_get?(:action => :update,:conds => {:id => '20091120_0001'}),
			"frank should be able to get.update his own item"
		)
		assert(
			sd.workflow.permit_get?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"frank should be able to get.delete his own item"
		)
	end

	def testpermit_frank_post?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'frank' # frank is an admin of foo/bar/
		assert(
			sd.workflow.permit_post?('_1234' => {'name' => 'foo'}),
			'frank should be able to post.create'
		)
		assert(
			sd.workflow.permit_post?('20091120_0001' => {'name' => 'foo'}),
			"frank should be able to post.update carl's item"
		)
		assert(
			sd.workflow.permit_post?('20091120_0001' => {'_action' => 'delete'}),
			"frank should be able to post.delete carl's item"
		)
	end

	def testpermit_abnormal_action?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'frank'
		assert(
			!sd.workflow.permit_get?(:action => :'***'),
			'frank should not get.*** on the stage'
		)
		assert(
			!sd.workflow.permit_post?('20091120_0001' => {'_action' => '***'}),
			'frank should not post.*** on the stage'
		)
	end

	class Sofa::Workflow::Test_Default_Action < Sofa::Workflow
		PERM = {
			:create => 'oo--',
			:read   => 'o---',
			:update => 'ooo-',
			:foo    => 'oooo',
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
			sd.workflow.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)

		Sofa.client = 'carl' # carl is not the member of the group
		assert_equal(
			:foo,
			sd.workflow.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)
		assert_equal(
			:update,
			sd.workflow.default_action(:conds => {:id => '20091122_0001'}),
			'Workflow#default_action should see the given conds'
		)

		Sofa.client = 'roy' # roy belongs to the group
		assert_equal(
			:create,
			sd.workflow.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)

		Sofa.client = 'frank' # frank is the admin
		assert_equal(
			:read,
			sd.workflow.default_action,
			'Workflow#default_action should return a permitted action for the client'
		)
	end

end
