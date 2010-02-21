# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage

	def self.instance(sd)
		if folder = sd[:folder]
			klass = Sofa['STORAGE']['default'].capitalize
			if klass == 'File' && folder != sd[:parent]
				Temp.new sd
			else
				self.const_get(klass).new sd
			end
		else
			Temp.new sd
		end
	end

	def self.available?
		false
	end

	attr_reader :sd

	def initialize(sd)
		@sd = sd
	end

	def select(conds = {})
		item_ids = _select(conds)
		item_ids = _sort(item_ids,conds)
		item_ids = _page(item_ids,conds)
	end

	def build(v)
		self
	end

	def clear
		self
	end

	def store(id,v)
		id
	end

	def delete(id)
		id
	end

	def navi(conds)
		conds[:p] = '1' unless conds[:p] || conds[:id] || (@sd[:p_size].to_i < 1)
		navi = {}
		(([:id,:p,:d] & conds.keys) | conds.keys).each {|cid|
			next unless conds[cid] && respond_to?("_sibs_#{cid}",true)
			sibs = __send__("_sibs_#{cid}",conds)

# TODO: should be cast in the upper tier?
c = (cid == :id) ? cast_ids(conds[cid]).first : conds[cid]
			c = c.first if c.is_a?(::Array) && c.size < 2
			if i = sibs.index(c)
				if !navi[:prev] && i > 0
					navi[:prev] = conds.merge(cid => sibs[i - 1])
					if ![:id,:p].include? cid
						navi[:prev][:id] = _select_without(:id,navi[:prev]).last if conds[:id]
						navi[:prev][:p] = _p_count(navi[:prev]).to_s if conds[:p]
					end
				end
				if !navi[:next] && i < (sibs.size - 1)
					navi[:next] = conds.merge(cid => sibs[i + 1])
					if ![:id,:p].include? cid
						navi[:next][:id] = _select_without(:id,navi[:next]).first if conds[:id]
						navi[:next][:p] = '1' if conds[:p]
					end
				end
			end
			navi[:sibs] ||= {cid => sibs} if navi[:prev] || navi[:next]

			break if navi[:prev] && navi[:next]
		}

		navi
	end

	def last(cid,conds)
		__send__("_sibs_#{cid}",conds).last
	end

	private

	def _select(conds)
		if conds[:id]
			_select_by_id(conds) | (@sd.instance_variable_get(:@item_object).keys & conds[:id].to_a)
		elsif cid = (conds.keys - [:order,:p]).first
			m = "_select_by_#{cid}"
			respond_to?(m,true) ? __send__(m,conds) : []
		else
			_select_all(conds) | @sd.instance_variable_get(:@item_object).keys
		end
	end

	def _sort(item_ids,conds)
		case conds[:order]
			when '-d','-id'
				item_ids.sort.reverse
			else
				item_ids.sort
		end
	end

	def _page(item_ids,conds)
		size = @sd[:p_size].to_i
		return item_ids if size < 1

		page = conds[:p].to_i
		page = 1 if page < 1
		item_ids[(page - 1) * size,size].to_a
	end

	def _sibs_id(conds)
		_select_without(:id,conds)
	end

	def _sibs_p(conds)
		p_count = _p_count(conds)
		p_count ? (1..p_count).collect {|i| i.to_s } : []
	end

	def _sibs_d(conds)
		rex_d = /^\d{#{conds[:d].length}}/
		_select_without(:id,:p,:d,conds).collect {|id| id[rex_d] }.uniq.compact
	end

	def _select_without(*cids)
		conds = cids.pop.dup
		cids.each {|cid| conds.delete cid }
		_sort(_select(conds),conds)
	end

	def _p_count(conds)
		(_select_without(:id,:p,conds).size / @sd[:p_size].to_f).ceil unless @sd[:p_size].to_f == 0
	end

	def cast_ids(ids)
		ids.to_a.collect {|i|
			id = (i =~ /^[a-z]/) ? "00000000_#{i}" : i
			id if id =~ Sofa::REX::ID
		}.compact
	end

	def new_id(v = {})
		return "00000000_#{v['_id']}" if v['_id'] =~ /\A#{Sofa::REX::ID_SHORT}\z/

		d = Time.now.strftime '%Y%m%d'
		if max_in_d = select(:d => d,:order => 'id').last
			d + '_%.4d' % (max_in_d[/\d{4}$/].to_i + 1)
		else
			d + '_0001'
		end
	end

end
