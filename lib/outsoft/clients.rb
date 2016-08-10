module Outsoft
  class Clients
    class << self
      # Update exists client
      #
      # options:
      #  * :id Id of client in db
      #  * :predefined Array of predefined parameters, which need update, format:
      #   [
      #     {'path': <path to parameter>, 'value': <new value of parameter>},
      #     ...
      #   ]
      #     for :path look at params.rb
      #  * :extra Additional parameters for user, It's Array with format:
      #   [
      #     [<parameter name>, <parameter value>],
      #      ...
      #   ]
      #   where <parameter name> and <parameter value> are string
      def update(id:, predefined: nil, extra: nil)
        client = Client.find id

        if predefined.present?
          raise 'Predefined must be an Array' unless predefined.is_a? Array
          predefined.each do |i|
            new_value = i['value']
            path = i['path']
            raise 'Predefined must contain items with `path` and `value`' unless path.present? && new_value.present?
            data = Outsoft::Params.get_inner_by_path path: path, data: client.predefined
            data['value'] = new_value
          end
        end

        if extra.present?
          raise 'Extra must be an Array' unless extra.is_a? Array
          client.extra = extra.deep_dup.delete_if { |i| i.size < 2 || !i[1].present? }
        end

        client.save!
      end

      def get(id:)
        Client.find id
      end

      def all
        Client.all
      end

      # Called from third party services
      def create(data:)
        client = Client.create! data
        client.predefined = Outsoft::Params.all
        client.save!
        client
      end
    end
  end
end
