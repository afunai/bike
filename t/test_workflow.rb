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

	def test__permit_guest?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { _permit?(:guest,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:guest,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { _permit?(:guest,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { _permit?(:guest,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test__permit_owner?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { _permit?(:owner,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:owner,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:owner,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { _permit?(:owner,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test__permit_group?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			wf.instance_eval { _permit?(:group,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:group,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			!wf.instance_eval { _permit?(:group,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:group,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test__permit_admin?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			wf.instance_eval { _permit?(:admin,:create) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:admin,:read) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:admin,:update) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
		assert(
			wf.instance_eval { _permit?(:admin,:delete) },
			'Set::Workflow#permit? should return whether it permits the client the action or not'
		)
	end

	def test__permit_abnormal_role?
		wf = Sofa::Workflow::Foo.new(nil)
		assert(
			!wf.instance_eval { _permit?(:'non-exist',:read) },
			'Set::Workflow#permit? should always return false for non-exist roles'
		)
		assert(
			!wf.instance_eval { _permit?(:admin,:'non-exist') },
			'Set::Workflow#permit? should always return false for non-exist actions'
		)
	end

	def test_permit_nobody?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')

		Sofa.client = nil
		assert(
			!sd.workflow.permit?(:action => :create),
			"'nobody' should not get.create"
		)
		assert(
			sd.workflow.permit?(:action => :read,:conds => {:id => '20091120_0001'}),
			"'nobody' should be able to get.read the item"
		)
		assert(
			!sd.workflow.permit?(:action => :update,:conds => {:id => '20091120_0001'}),
			"'nobody' should not get.update carl's item"
		)
		assert(
			!sd.workflow.permit?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"'nobody' should not get.delete carl's item"
		)
	end

	def test_permit_don?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')

		Sofa.client = 'don' # don belongs to the group of foo/bar/
		assert(
			sd.workflow.permit?(:action => :create),
			'don should be able to get.create'
		)
		assert(
			sd.workflow.permit?(:action => :read,:conds => {:id => '20091120_0001'}),
			'don should be able to get.read the item'
		)
		assert(
			!sd.workflow.permit?(:action => :update,:conds => {:id => '20091120_0001'}),
			"don should not get.update carl's item"
		)
		assert(
			sd.workflow.permit?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"don should be able to get.delete carl's item"
		)
	end

	def test_permit_carl?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')

		Sofa.client = 'carl' # carl belongs to the group of foo/bar/, and the owner of the item #0001
		assert(
			sd.workflow.permit?(:action => :create),
			'carl should be able to get.create'
		)
		assert(
			sd.workflow.permit?(:action => :read,:conds => {:id => '20091120_0001'}),
			'carl should be able to get.read the item'
		)
		assert(
			sd.workflow.permit?(:action => :update,:conds => {:id => '20091120_0001'}),
			"carl should be able to get.update his own item"
		)
		assert(
			sd.workflow.permit?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"carl should be able to get.delete his own item"
		)
	end

	def test_permit_frank?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')

		Sofa.client = 'frank' # frank is an admin of foo/bar/
		assert(
			sd.workflow.permit?(:action => :create),
			'frank should be able to get.create'
		)
		assert(
			sd.workflow.permit?(:action => :read,:conds => {:id => '20091120_0001'}),
			'frank should be able to get.read the item'
		)
		assert(
			sd.workflow.permit?(:action => :update,:conds => {:id => '20091120_0001'}),
			"frank should be able to get.update his own item"
		)
		assert(
			sd.workflow.permit?(:action => :delete,:conds => {:id => '20091120_0001'}),
			"frank should be able to get.delete his own item"
		)
	end

	def test_permit_abnormal_action?
		sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')
		Sofa.client = 'frank'
		assert(
			!sd.workflow.permit?(:action => :'***'),
			'frank should not get.*** on the stage'
		)
	end

def ptest_permit_nobody_post?
	sd = Sofa::Set::Static::Folder.root.item('foo','bar','main')

	Sofa.client = nil
	assert(
		!sd.workflow.permit?(:action => :create),
		"'nobody' should not be able to get.create"
	)
	assert(
		sd.workflow.permit?(:action => :read,:conds => {:id => '20091120_0001'}),
		"'nobody' should be able to get.read the item"
	)
	assert(
		!sd.workflow.permit?(:action => :update,:conds => {:id => '20091120_0001'}),
		"'nobody' should not be able to get.update carl's item"
	)
	assert(
		!sd.workflow.permit?(:action => :delete,:conds => {:id => '20091120_0001'}),
		"'nobody' should not be able to get.delete carl's item"
	)
end

end
