# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Bike::Set::Dynamic

  private

  def _g_message(arg)
    return if arg[:orig_action] == :done && my[:tmpl][:done]
    return unless self == Bike.base

    if arg[:dest_action]
      message = {:alert => _('please login.')}
    elsif arg[:orig_action] == :preview
      message = {:notice => _('please confirm.')}
    elsif !self.valid? && arg[:orig_action] != :create
      message = {:error => _('malformed input.')}
    elsif Bike.transaction[my[:tid]].is_a? ::Hash
      message = {
        :notice => Bike.transaction[my[:tid]].keys.collect {|item_result|
          n = Bike.transaction[my[:tid]][item_result]
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
      } unless Bike.transaction[my[:tid]].empty?
      Bike.transaction[my[:tid]] = :expired
    end

    message.keys.collect {|type|
      lis = Array(message[type]).collect {|m| "  <li>#{Bike::Field.h m}</li>\n" }
      <<_html
<ul class="message #{type}">
#{lis.join}</ul>
_html
    }.join if message
  end

end
