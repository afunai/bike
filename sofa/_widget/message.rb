# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Dynamic

	private

	def _g_message(arg)
		return if arg[:orig_action] == :done && my[:tmpl_done]
		return unless self == Sofa.base

		if arg[:dest_action]
			message = {:alert => _('please login.')}
		elsif arg[:orig_action] == :preview
			message = {:notice => _('please confirm.')}
		elsif !self.valid? && arg[:orig_action] != :create
			message = {:error => _('malformed input.')}
		elsif Sofa.transaction[my[:tid]].is_a? ::Hash
			message = {
				:notice => Sofa.transaction[my[:tid]].keys.collect {|item_result|
					n = Sofa.transaction[my[:tid]][item_result]
					_('%{result} %{n} %{item}.') % {
						:result => {
							:create => _('created'),
							:update => _('updated'),
							:delete => _('deleted'),
						}[item_result],
						:n      => n,
						:item   => n_(
							(my[:item].size == 1 && my[:item]['default'][:label]) || my[:item_label],
							'',
							n
						)
					}
				}
			} unless Sofa.transaction[my[:tid]].empty?
			Sofa.transaction[my[:tid]] = :expired
		end

		message.keys.collect {|type|
			lis = message[type].collect {|m| "\t<li>#{Sofa::Field.h m}</li>\n" }
			<<_html
<ul class="message #{type}">
#{lis}</ul>
_html
		}.join if message
	end

end
