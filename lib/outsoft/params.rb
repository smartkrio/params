module Outsoft
  # == Wrapper for work with params
  #
  # Implement logic for add, update and remove params
  class Params
    class << self
      # Add parameter to root level
      #
      # options:
      #  * :name String, which will be used like json key, needed for searchig params
      #  * :value_type Type of value (int, ref, group, date, string)
      #  * :value Value of new element, depend to :value_type (for int - number, for string - some string,
      #     for groups and ref it woill ignored)
      #  * :label String with name of parameter, which will displayed to user
      #  * :company_id Company identifier in
      #
      def add(name:, value_type:, label:, value:nil, company_id: 1)
        # Value must be [] if group or ref created (in this case method will ignore :value)
        inserted_value = value
        if %w(ref group).include? value_type
          inserted_value = {}
          raise 'Value must be a Hash' unless inserted_value == {}
        end

        Param.create! company_id: company_id, name: name,
                        data: { name => { value_type: value_type, label: label, value: inserted_value } }
      end

      # Add parameter by presented path
      #
      # Path examples:
      #  some_name.nested_name
      #  some_name.*
      #
      # options:
      #  * :path String with path to need value
      #  * :name String, which will be used like json key, needed for searchig params
      #  * :value_type Type of value (int, ref, group, date, string)
      #  * :value Value of new element, depend to :value_type (for int - number, for string - some string,
      #     for groups and ref it woill ignored)
      #  * :label String with name of parameter, which will displayed to user
      #
      def add_by_path(path:, name:, value_type:, label:, value:nil)
        # Value must be [] if group or ref created (in this case method will ignore :value)
        inserted_value = value
        inserted_value = {} if %w(ref group).include? value_type

        param = get_by_name(path: path)
        raise "Undefined params by path #{path}" unless param.present?

        data = get_inner_by_path path: path, data: param.data

        raise 'You can add nested params only inside ref and group' unless %w(ref group).include? data['value_type']
        raise "#{name} param already exists in #{path}" if data['value'][name].present?
        data['value'][name] = {
          'label' => label,
          'value' => inserted_value,
          'value_type' => value_type
        }

        param.save!
      end

      # Update parameter by presented path
      #
      # Path examples:
      #  some_name.nested_name
      #  some_name.*
      #
      # options:
      #  * :path String with path to need value
      #  * :name String, which will be used like json key, needed for searchig params
      #  * :value_type Type of value (int, ref, group, date, string)
      #  * :value Value of new element, depend to :value_type (for int - number, for string - some string,
      #     for groups and ref it woill ignored)
      #  * :label String with name of parameter, which will displayed to user
      #  * :company_id Company identifier in
      #
      def update(path:, value_type: nil, value: nil, label:nil, name: nil, company_id: nil)
        param = get_by_name(path: path)
        raise "Undefined params by path #{path}" unless param.present?
        data = get_inner_by_path path: path, data: param.data
        data_wrapper = get_parent_by_path path: path, data: param.data

        unless name.nil?
          old_name = path.split('.').last
          param.name = name if path.split('.').size == 1
          data_wrapper[name] = data
          data_wrapper.delete old_name
          data = data_wrapper[name]
        end

        param.company_id = company_id unless company_id.nil?

        unless value_type.nil?
          data['value'] = Param.default_value value_type unless data['value_type'] == value_type
          data['value_type'] = value_type
        end

        data['value'] = value unless value.nil?
        data['label'] = label unless label.nil?
        param.save!
      end

      # Remove parameter by presented path
      #
      # Path examples:
      #  some_name.nested_name
      #  some_name.*
      #
      # options:
      #  * :path String with path to need value
      #
      def remove(path:)
        param = get_by_name(path: path)
        raise "Undefined params by path #{path}" unless param.present?

        path_array = path.split '.'
        return param.delete if path_array.size == 1

        data_wrapper = get_parent_by_path path: path, data: param.data
        data_wrapper.delete path_array.last
        param.save!
      end

      # Get parameters array by presented path
      #
      # Path examples:
      #  some_name.nested_name
      #  some_name.*
      #
      # options:
      #  * :path String with path to need value
      #
      # :return array in format:
      # [
      #   {
      #      'name': <parameter name>,
      #      'value': <parameter value>,
      #      'value_type': <parameter type>,
      #      'label': <parameter label>,
      #   },
      #   ...
      # ]
      #
      def get(path:)
        raise 'Path can\'t be *' if path == '*'

        param = get_by_name(path: path)
        result = []
        raise "Undefined params by path #{path}" unless param.present?

        path_array = path.split('.')
        last_path_item = path_array.last

        if last_path_item == '*'
          wrapper_path = path_array.first(path_array.size - 1).join '.'
          data_wrapper = get_inner_by_path path: wrapper_path, data: param.data
          raise 'Can\'t get * values not from ref' unless data_wrapper['value_type'] == 'ref'
          data_wrapper['value'].each do |k, v|
            buffer = v.deep_dup
            buffer['name'] = k
            result << buffer.as_json
          end
        else
          data = get_inner_by_path(path: path, data: param.data).deep_dup
          not_simple_type = %w(ref group).include? data['value_type']
          raise "Can't get simple value by #{path}, because it's #{data['value_type']}" if not_simple_type
          data['name'] = last_path_item
          result << data.as_json
        end

        result
      end

      def remove_by_id(id:)
        Param.delete id
      end

      def get_by_name(path:)
        raise 'Incorrect path' unless path.is_a?(String) && path.present?
        Param.find_by name: path.split('.').first
      end

      def get_inner_by_path(path:, data:)
        res = { 'value' => data }
        path.split('.').each do |i|
          raise "Undefined params by path #{path}" unless res['value'].present? && res['value'][i].present?
          res = res['value'][i]
        end
        res
      end

      def get_parent_by_path(path:, data:)
        path_array = path.split('.')
        return data if path_array.size == 1
        res = data
        path_array = path_array.first path_array.size - 1
        path_array.each do |i|
          raise "Undefined params by path #{path}" unless res[i].present? && res[i]['value'].present?
          res = res[i]['value']
        end
        res
      end

      def all
        res = {}
        Param.all.each { |i| res[i.name] = i.data[i.name] }
        res
      end
    end
  end
end
