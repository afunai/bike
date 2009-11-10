# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Storage < Test::Unit::TestCase

	def setup
		@list = Sofa::Field.instance(
			:klass  => 'list',
			:id     => 'main',
			:parent => Sofa::Field.instance(:id => 'foo',:klass => 'set-folder')
		)
	end

	def teardown
	end

	def test_file_instance
		assert_instance_of(
			Sofa::Storage::File,
			Sofa::Storage.instance(@list),
			'Storage.instance should return a File instance when the list is right under the folder'
		)

		child_list = Sofa::Field.instance(
			:klass  => 'list',
			:parent => @list
		)
		assert_instance_of(
			Sofa::Storage::Val,
			Sofa::Storage.instance(child_list),
			'Storage.instance should return a Val instance when the list is apart from the folder'
		)

		orphan_list = Sofa::Field.instance(
			:klass  => 'list'
		)
		assert_instance_of(
			Sofa::Storage::Val,
			Sofa::Storage.instance(orphan_list),
			'Storage.instance should return a Val instance when the list has no parent folder'
		)
	end

	def test_select
	end

end


__END__

List.val == queue
storage.item should first look in list.val, then the 'real' storage.

