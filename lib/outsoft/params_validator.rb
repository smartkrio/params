module Outsoft
  class ParamsValidator < ActiveModel::Validator
    def self.value_types
      {
        'int' => 0,
        'date' => '01-01-1970',
        'group' => {},
        'string' => 'n/a',
        'ref' => {}
      }
    end

    def validate_fields
      [
        { name: 'value_type', in: ParamsValidator.value_types.keys },
        { name: 'value', method: 'check_value' },
        { name: 'label', method: 'check_string' }
      ]
    end

    def validate(record)
      return unless record.name.present?
      unless record.data[record.name].present?
        record.errors[:name] = 'Record name and data.name must be the same'
        return
      end

      check_data("data.#{record.name}", record.name, record.data[record.name], record.errors)
    end

    def check_data(path, name, data, errors)
      unless data.is_a? Hash
        errors[:data] = "#{path} must be a Hash"
        return
      end

      return false unless check_string path, 'name', name, errors

      value_type = data['value_type'] rescue nil

      validate_fields.each do |i|
        key = i[:name]
        method = i[:method]
        value = data[i[:name]]

        can_be_nil = i[:nil].present? ? i[:nil] : false
        in_array = i[:in]

        if value.nil?
          errors[key] = "is require #{path}" unless can_be_nil
          next
        end

        if method.present?
          send method, path, key, value, errors, value_type
          next
        end

        if in_array.present?
          errors[key] = "#{path} #{key} must be in #{in_array}" unless in_array.include? value
          next
        end
      end
    end

    def check_value(path, key, value, errors, options)
      method_name = "check_#{options}"

      if respond_to? method_name
        send method_name, "#{path}.#{key}", key, value, errors, options
      else
        errors[key] = "in #{path} incorrect value type #{options}"
      end
    end

    def check_group(path, key, value, errors, _options)
      unless value.is_a? Hash
        errors[key] = "in #{path} Group value must be a hash"
        return false
      end

      value.each do |k, v|
        return false unless check_data "#{path}.#{k}", k, v, errors
      end
    end

    def check_ref(path, key, value, errors, _options)
      unless value.is_a? Hash
        errors[key] = "in #{path} ref value must be a hash"
        return false
      end
      value.each do |k, v|
        return false unless check_data "#{path}.#{k}", k, v, errors
        if %w(ref group).include? v['value_type']
          errors[key] = "#{path} ref can contain only simple values"
          return false
        end
      end
    end

    def check_int(path, key, value, errors, _options)
      errors[key] = "In #{path} #{key} must be integer" unless value.is_a? Integer
    end

    def check_date(path, key, value, errors, _options)
      Date.parse value
    rescue ArgumentError
      errors[key] = "in #{path} incorrect date format"
    end

    def check_string(path, key, value, errors, _options = nil)
      unless value.is_a?(String) && value.size >= 1 && value.size < 255
        errors[key] = "in #{path} #{key} must be String with length 1...255"
        return false
      end
      true
    end
  end
end
