# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Timestamp < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar('$(foo meta-timestamp)') {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta
	end

	def teardown
	end

	def test_meta
		meta = nil
		Sofa::Parser.gsub_scalar('$(foo meta-timestamp can_edit)') {|id,m|
			meta = m
			''
		}
		f = Sofa::Field.instance meta
		assert_equal(
			true,
			f[:can_edit],
			'Timestamp#initialize should set :can_edit from the tokens'
		)

		meta = nil
		Sofa::Parser.gsub_scalar('$(foo meta-timestamp can_update)') {|id,m|
			meta = m
			''
		}
		f = Sofa::Field.instance meta
		assert_equal(
			true,
			f[:can_update],
			'Timestamp#initialize should set :can_update from the tokens'
		)
	end

	def test_val_cast
		v = nil
		assert_equal(
			{},
			@f.send(:val_cast,v),
			'Timestamp#val_cast should return an empty hash if the val is not a hash nor a string'
		)

		v = {
			'create'  => Time.local(2010,4,1),
			'update'  => Time.local(2010,4,3),
			'publish' => Time.local(2010,4,2),
		}
		assert_equal(
			v,
			@f.send(:val_cast,v),
			'Timestamp#val_cast should pass through if the val is a hash'
		)

		v = 'true'
		assert_equal(
			{'publish' => :same_as_update},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should set v['publish'] to :same_as_update if the val is 'true'"
		)

		v = '2010/4/26'
		assert_equal(
			{'publish' => Time.local(2010,4,26)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['publish'] if the val represents a date"
		)
		v = '2010-4-26'
		assert_equal(
			{'publish' => Time.local(2010,4,26)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['publish'] if the val represents a date"
		)
		v = '2010-4-26 20:14'
		assert_equal(
			{'publish' => Time.local(2010,4,26,20,14)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['publish'] if the val represents a date"
		)
		v = '2010-4-26 20:14:45'
		assert_equal(
			{'publish' => Time.local(2010,4,26,20,14,45)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['publish'] if the val represents a date"
		)
	end

	def ptest_get
		@f.load 'bar'
		assert_equal(
			'bar',
			@f.get,
			'Timestamp#get should return proper string'
		)
		assert_equal(
			'<input type="timestamp" name="" value="bar" class="" />',
			@f.get(:action => :update),
			'Timestamp#get should return proper string'
		)
	end

	def test_errors
		@f.load nil
		assert_equal(
			[],
			@f.errors,
			'Timestamp#errors should return the errors of the current val'
		)

		@f.load '2010-4-26 20:14:45'
		assert_equal(
			[],
			@f.errors,
			'Timestamp#errors should return the errors of the current val'
		)

		@f.load 'someday'
		assert_equal(
			['wrong format'],
			@f.errors,
			'Timestamp#errors should return the errors of the current val'
		)
	end

	def test_load
		@f.load(
			'create'  => Time.local(2010,4,1),
			'update'  => Time.local(2010,4,3),
			'publish' => Time.local(2010,4,2)
		)
		assert_equal(
			{
				'create'  => Time.local(2010,4,1),
				'update'  => Time.local(2010,4,3),
				'publish' => Time.local(2010,4,2)
			},
			@f.val,
			'Timestamp#load should load the given val like a normal field'
		)
		assert_nil(
			@f.action,
			'Timestamp#load should not set @action'
		)
		assert_equal(
			:load,
			@f.result,
			'Timestamp#load should set @result like a normal field'
		)
	end

	def test_create
		@f.create nil
		assert_equal(
			@f.val['update'],
			@f.val['create'],
			'Timestamp#create should set the default vals'
		)
		assert_equal(
			@f.val['publish'],
			@f.val['create'],
			'Timestamp#create should set the default vals'
		)
		assert_nil(
			@f.action,
			"Timestamp#create should not set @action without v['publish']"
		)
		assert_nil(
			@f.result,
			'Timestamp#create should not set @result'
		)
	end

	def test_create_with_date
		@f[:can_edit] = true
		@f.create '2010/4/26'
		assert_equal(
			@f.val['update'],
			@f.val['create'],
			'Timestamp#create should set the default vals'
		)
		assert_equal(
			Time.local(2010,4,26),
			@f.val['publish'],
			"Timestamp#create should set @val['publish'] if v['publish'] is a date"
		)
		assert_equal(
			:create,
			@f.action,
			"Timestamp#create should set @action if v['publish'] is a date"
		)
	end

	def test_create_with_check
		@f[:can_update] = true
		@f.create 'true'
		assert_equal(
			@f.val['update'],
			@f.val['create'],
			'Timestamp#create should set the default vals'
		)
		assert_equal(
			@f.val['publish'],
			@f.val['create'],
			'Timestamp#create should set the default vals'
		)
		assert_nil(
			@f.action,
			"Timestamp#create should not set @action if v['publish'] is not a date"
		)
	end

	def test_update
		@f.load(
			'create'  => Time.local(2010,4,1),
			'update'  => Time.local(2010,4,3),
			'publish' => Time.local(2010,4,2)
		)

		@f.update nil
		assert_equal(
			Time.local(2010,4,1),
			@f.val['create'],
			"Timestamp#update should keep @val['create']"
		)
		assert_not_equal(
			Time.local(2010,4,3),
			@f.val['update'],
			"Timestamp#update should update @val['update']"
		)
		assert_equal(
			Time.local(2010,4,2),
			@f.val['publish'],
			"Timestamp#update should keep @val['publish']"
		)
		assert_nil(
			@f.action,
			"Timestamp#update should not set @action without v['publish']"
		)
		assert_nil(
			@f.result,
			'Timestamp#update should not set @result'
		)
	end

	def test_update_with_date
		@f[:can_edit] = true
		@f.load(
			'create'  => Time.local(2010,4,1),
			'update'  => Time.local(2010,4,3),
			'publish' => Time.local(2010,4,2)
		)

		@f.update '2010/4/26'
		assert_equal(
			Time.local(2010,4,1),
			@f.val['create'],
			"Timestamp#update should keep @val['create']"
		)
		assert_not_equal(
			Time.local(2010,4,3),
			@f.val['update'],
			"Timestamp#update should update @val['update']"
		)
		assert_equal(
			Time.local(2010,4,26),
			@f.val['publish'],
			"Timestamp#update should set @val['publish'] if v['publish'] is a date"
		)
		assert_equal(
			:update,
			@f.action,
			"Timestamp#update should set @action if v['publish'] is a date"
		)
		assert_nil(
			@f.result,
			'Timestamp#update should not set @result'
		)
	end

	def test_update_with_check
		@f[:can_update] = true
		@f.load(
			'create'  => Time.local(2010,4,1),
			'update'  => Time.local(2010,4,3),
			'publish' => Time.local(2010,4,2)
		)

		@f.update 'true'
		assert_equal(
			Time.local(2010,4,1),
			@f.val['create'],
			"Timestamp#update should keep @val['create']"
		)
		assert_not_equal(
			Time.local(2010,4,3),
			@f.val['update'],
			"Timestamp#update should update @val['update']"
		)
		assert_equal(
			@f.val['update'],
			@f.val['publish'],
			"Timestamp#update should update @val['publish'] if v['publish'] is :same_as_update"
		)
		assert_equal(
			:update,
			@f.action,
			"Timestamp#update should set @action if v['publish'] is :same_as_update"
		)
		assert_nil(
			@f.result,
			'Timestamp#update should not set @result'
		)
	end

end
