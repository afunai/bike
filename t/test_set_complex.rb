# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Complex < Test::Unit::TestCase

	class ::Sofa::Workflow::Pipco < ::Sofa::Workflow
		PERM = {
			:create => 'oo--',
			:read   => 'oooo',
			:update => 'ooo-',
			:delete => 'o-o-',
		}
	end

	class ::Sofa::Tomago < ::Sofa::Field
		def get(arg)
			"'#{val}'(#{arg.sort.join ','})"
		end
	end

	def setup
		# Set::Dynamic of Set::Static of (Scalar and (Set::Dynamic of Set::Static of Scalar))
		@sd = Sofa::Set::Dynamic.new(
			:id        => 'main',
			:klass     => 'set-dynamic',
			:workflow  => 'pipco',
			:group     => ['roy','don'],
			:tmpl      => <<'_tmpl',
<ul id="foo" class="sofa-pipco">
$()</ul>
_tmpl
			:item_html => <<'_html'
	<li>
		name:(tomago 32 :'nobody'): comment:(tomago 64 :'hi.')
		<ul id="files" class="sofa-pipco">
<li>file:(tomago :'foo.jpg')</li>
		</ul>
		%(bar-navi)
	</li>
_html
		)
		def @sd.meta_admins
			['frank']
		end
		@sd.load(
			'20091123_0001' => {
				'_owner'  => 'carl',
				'name'    => 'CZ',
				'comment' => 'oops',
				'files'   => {
					'20091123_0001' => {'file' => 'carl1.jpg'},
					'20091123_0002' => {'file' => 'carl2.jpg'},
				},
			},
			'20091123_0002' => {
				'_owner'  => 'roy',
				'name'    => 'RE',
				'comment' => 'wee',
				'files'   => {
					'20091123_0001' => {'file' => 'roy.png'},
				},
			}
		)
	end

	def teardown
		Sofa.client = nil
	end

	def test_get_default
		assert_equal(
			<<'_html',
<ul id="foo" class="sofa-pipco">
	<li>
		'CZ'(action,read): 'oops'(action,read)
		<ul id="files" class="sofa-pipco"><li>'carl1.jpg'(action,read)</li>
<li>'carl2.jpg'(action,read)</li>
</ul>

		%(bar-navi)
	</li>
	<li>
		'RE'(action,read): 'wee'(action,read)
		<ul id="files" class="sofa-pipco"><li>'roy.png'(action,read)</li>
</ul>

		%(bar-navi)
	</li>
</ul>
_html
			@sd.get,
			'Set#get should work recursively as a part of the complex'
		)
	end

end
