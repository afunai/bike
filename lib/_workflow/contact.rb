# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Workflow::Contact < Bike::Workflow

  DEFAULT_META = {
    :p_size     => 10,
    :conds      => {:p => 'last'},
    :item_label => Bike::I18n.n_('item', 'items', 1),
  }

  DEFAULT_SUB_ITEMS = {}

  PERM = {
    :create => 0b00011,
    :read   => 0b11000,
    :update => 0b00000,
    :delete => 0b11000,
  }

end
