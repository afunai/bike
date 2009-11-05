# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Field::Foo < Sofa::Field
	class Bar < Sofa::Field
	end
end

class TC_Field < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_instance
		f = Sofa::Field.instance :klass => 'foo-bar'
		assert_instance_of(
			Sofa::Field::Foo::Bar,
			f,
			'Field#instance should return an instance of the class specified by :klass'
		)
	end

end
