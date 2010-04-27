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
			'created'   => Time.local(2010,4,1),
			'updated'   => Time.local(2010,4,3),
			'published' => Time.local(2010,4,2),
		}
		assert_equal(
			v,
			@f.send(:val_cast,v),
			'Timestamp#val_cast should pass through if the val is a hash'
		)

		v = 'true'
		assert_equal(
			{'published' => :same_as_updated},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should set v['published'] to :same_as_updated if the val is 'true'"
		)

		v = '2010/4/26'
		assert_equal(
			{'published' => Time.local(2010,4,26)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['published'] if the val represents a date"
		)
		v = '2010-4-26'
		assert_equal(
			{'published' => Time.local(2010,4,26)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['published'] if the val represents a date"
		)
		v = '2010-4-26 20:14'
		assert_equal(
			{'published' => Time.local(2010,4,26,20,14)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['published'] if the val represents a date"
		)
		v = '2010-4-26 20:14:45'
		assert_equal(
			{'published' => Time.local(2010,4,26,20,14,45)},
			@f.send(:val_cast,v),
			"Timestamp#val_cast should cast the val to v['published'] if the val represents a date"
		)

		v = '2010-4-89'
		assert_equal(
			{},
			@f.send(:val_cast,v),
			'Timestamp#val_cast should return an empty hash if the given date is out of range'
		)
	end

	def test_get
		@f.load(
			'created'   => Time.local(2010,4,25),
			'updated'   => Time.local(2010,4,27),
			'published' => Time.local(2010,4,26,20,14,45)
		)
		assert_equal(
			'2010-04-26T20:14:45',
			@f.get,
			'Timestamp#get should return proper string'
		)
		assert_equal(
			'2010-04-25T00:00:00',
			@f.get(:action => :created),
			'Timestamp#get should return proper string'
		)
		assert_equal(
			'2010-04-27T00:00:00',
			@f.get(:action => :updated),
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
		@f.load ''
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
		@f.load '2010-4-89'
		assert_equal(
			['out of range'],
			@f.errors,
			'Timestamp#errors should return the errors of the current val'
		)
	end

	def test_load
		@f.load(
			'created'   => Time.local(2010,4,1),
			'updated'   => Time.local(2010,4,3),
			'published' => Time.local(2010,4,2)
		)
		assert_equal(
			{
				'created'   => Time.local(2010,4,1),
				'updated'   => Time.local(2010,4,3),
				'published' => Time.local(2010,4,2)
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
			@f.val['updated'],
			@f.val['created'],
			'Timestamp#create should set the default vals'
		)
		assert_equal(
			@f.val['published'],
			@f.val['created'],
			'Timestamp#create should set the default vals'
		)
		assert_nil(
			@f.action,
			"Timestamp#create should not set @action without v['published']"
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
			@f.val['updated'],
			@f.val['created'],
			'Timestamp#create should set the default vals'
		)
		assert_equal(
			Time.local(2010,4,26),
			@f.val['published'],
			"Timestamp#create should set @val['published'] if v['published'] is a date"
		)
		assert_equal(
			:create,
			@f.action,
			"Timestamp#create should set @action if v['published'] is a date"
		)
	end

	def test_create_with_check
		@f[:can_update] = true
		@f.create 'true'
		assert_equal(
			@f.val['updated'],
			@f.val['created'],
			'Timestamp#create should set the default vals'
		)
		assert_equal(
			@f.val['published'],
			@f.val['created'],
			'Timestamp#create should set the default vals'
		)
		assert_nil(
			@f.action,
			"Timestamp#create should not set @action if v['published'] is not a date"
		)
	end

	def test_update
		@f.load(
			'created'   => Time.local(2010,4,1),
			'updated'   => Time.local(2010,4,3),
			'published' => Time.local(2010,4,2)
		)

		@f.update nil
		assert_equal(
			Time.local(2010,4,1),
			@f.val['created'],
			"Timestamp#update should keep @val['created']"
		)
		assert_not_equal(
			Time.local(2010,4,3),
			@f.val['updated'],
			"Timestamp#update should updated @val['updated']"
		)
		assert_equal(
			Time.local(2010,4,2),
			@f.val['published'],
			"Timestamp#update should keep @val['published']"
		)
		assert_nil(
			@f.action,
			"Timestamp#update should not set @action without v['published']"
		)
		assert_nil(
			@f.result,
			'Timestamp#update should not set @result'
		)
	end

	def test_update_with_date
		@f[:can_edit] = true
		@f.load(
			'created'   => Time.local(2010,4,1),
			'updated'   => Time.local(2010,4,3),
			'published' => Time.local(2010,4,2)
		)

		@f.update '2010/4/26'
		assert_equal(
			Time.local(2010,4,1),
			@f.val['created'],
			"Timestamp#update should keep @val['created']"
		)
		assert_not_equal(
			Time.local(2010,4,3),
			@f.val['updated'],
			"Timestamp#update should updated @val['updated']"
		)
		assert_equal(
			Time.local(2010,4,26),
			@f.val['published'],
			"Timestamp#update should set @val['published'] if v['published'] is a date"
		)
		assert_equal(
			:update,
			@f.action,
			"Timestamp#update should set @action if v['published'] is a date"
		)
		assert_nil(
			@f.result,
			'Timestamp#update should not set @result'
		)
	end

	def test_update_can_not_edit
		@f[:can_edit] = false
		@f.load(
			'created'   => Time.local(2010,4,1),
			'updated'   => Time.local(2010,4,3),
			'published' => Time.local(2010,4,2)
		)

		@f.update '2010/4/26'
		assert_equal(
			Time.local(2010,4,2),
			@f.val['published'],
			"Timestamp#update should not set @val['published'] unless my[:can_edit]"
		)
		assert_nil(
			@f.action,
			"Timestamp#update should not set @action unless my[:can_edit]"
		)
	end

	def test_update_with_check
		@f[:can_update] = true
		@f.load(
			'created'   => Time.local(2010,4,1),
			'updated'   => Time.local(2010,4,3),
			'published' => Time.local(2010,4,2)
		)

		@f.update 'true'
		assert_equal(
			Time.local(2010,4,1),
			@f.val['created'],
			"Timestamp#update should keep @val['created']"
		)
		assert_not_equal(
			Time.local(2010,4,3),
			@f.val['updated'],
			"Timestamp#update should updated @val['updated']"
		)
		assert_equal(
			@f.val['updated'],
			@f.val['published'],
			"Timestamp#update should updated @val['published'] if v['published'] is :same_as_updated"
		)
		assert_equal(
			:update,
			@f.action,
			"Timestamp#update should set @action if v['published'] is :same_as_updated"
		)
		assert_nil(
			@f.result,
			'Timestamp#update should not set @result'
		)
	end

end
