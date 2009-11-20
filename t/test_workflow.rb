# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Workflow < Test::Unit::TestCase

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

end
