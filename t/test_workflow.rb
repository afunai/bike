# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Workflow < Test::Unit::TestCase

	class Sofa::Workflow::Foo < Sofa::Workflow
		PERM = {
			:create => 'oo--',
			:read   => 'oooo',
			:update => 'o-o-',
			:delete => 'o---',
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

	def test_permit_admin?
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

	def test_permit_group?
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
			!wf.instance_eval { permit?(:group,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test_permit_owner?
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

	def test_permit_guest?
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

	def test_permit_abnormal?
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

	def test_permit_nobody_get?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')

		Sofa.client = nil
		assert(
			!sd.workflow.permit_get?(:action => :create),
			"'nobody' should not be able to get.create"
		)
		assert(
			sd.workflow.permit_get?(:action => :read,:conds => {:id => '20091120_0001'}),
			"'nobody' should be able to get.read the item"
		)
		assert(
			!sd.workflow.permit_get?(:action => :update,:conds => {:id => '20091120_0001'}),
			"'nobody' should not be able to get.update carl's item"
		)
		assert(
			!sd.workflow.permit_get?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"'nobody' should not be able to get.delete carl's item"
		)
	end

	def test_permit_don_get?
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
			"don should not be able to get.delete carl's item"
		)
	end

	def test_permit_carl_get?
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

	def test_permit_frank_get?
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

end
