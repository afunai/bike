# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Bike::Workflow::Register < Bike::Workflow

  DEFAULT_META = {
    :p_size     => 0,
    :conds      => {:p => '1'},
    :order      => 'id',
    :item_label => Bike::I18n.n_('item', 'items', 1),
  }

  DEFAULT_SUB_ITEMS = {
    '_owner'     => {:klass => 'meta-owner'},
    '_timestamp' => {:klass => 'meta-timestamp'},
  }

  PERM = {
    :create => 0b11001,
    :read   => 0b11100,
    :update => 0b11100,
    :delete => 0b11100,
  }

  private

  def __p_update(params)
    super
    @f.send(:pending_items).each {|id, item|
      if id =~ Bike::REX::ID_NEW
        item.item('_owner').instance_variable_set(:@val, item.item('_id').val)
      end
    }
  end

  def __p_next_action
    (Bike.client == 'nobody') ? :done : super
  end

end
