# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Dynamic

  private

  def _g_message(arg)
    return if arg[:orig_action] == :done && my[:tmpl_done]
    return unless self == Runo.base

    if arg[:dest_action]
      message = {:alert => _('please login.')}
    elsif arg[:orig_action] == :preview
      message = {:notice => _('please confirm.')}
    elsif !self.valid? && arg[:orig_action] != :create
      message = {:error => _('malformed input.')}
    elsif Runo.transaction[my[:tid]].is_a? ::Hash
      message = {
        :notice => Runo.transaction[my[:tid]].keys.collect {|item_result|
          n = Runo.transaction[my[:tid]][item_result]
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
      } unless Runo.transaction[my[:tid]].empty?
      Runo.transaction[my[:tid]] = :expired
    end

    message.keys.collect {|type|
      lis = message[type].collect {|m| "  <li>#{Runo::Field.h m}</li>\n" }
      <<_html
<ul class="message #{type}">
#{lis}</ul>
_html
    }.join if message
  end

end
