require 'spec_helper'

describe Outsoft::Params do
  context '.add' do
    let(:name) { 'test_field' }
    let(:value_type) { 'int' }
    let(:value) { 10 }
    let(:label) { 'test' }
    let(:company_id) { 1 }

    subject { Outsoft::Params.add(name: name, value_type: value_type, value: value, label: label, company_id: company_id) }
    before(:each) do
      DatabaseCleaner.start
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    it 'should add parameter' do
      expect(subject).to be_valid
    end

    context 'when company_id is nil' do
      let(:company_id) { nil }

      it 'should add parameter' do
        expect(subject).to be_valid
      end
    end

    context 'when name incorrect' do
      let(:name) { nil }

      it 'should raise exception' do
        expect { subject }.to raise_exception ActiveRecord::RecordInvalid, 'Validation failed: Name can\'t be blank'
      end
    end

    context 'when parameter is string' do
      let(:name) { 'string_param' }
      let(:value_type) { 'string' }
      let(:value) { 'test string' }
      let(:label) { 'string_param' }

      it 'should add parameter' do
        expect(subject).to be_valid
      end
    end

    context 'when parameter is date' do
      let(:name) { 'date_param' }
      let(:value_type) { 'date' }
      let(:value) { '22-02-2010' }
      let(:label) { 'date_param' }

      it 'should add parameter' do
        expect(subject).to be_valid
      end

      context 'when date is nil' do
        let(:value) { nil }

        it 'should raise exception' do
          expect { subject }.to raise_exception ActiveRecord::RecordInvalid,
                                                "Validation failed: Value is require data.#{name}"
        end
      end

      context 'when date has incorrect format' do
        let(:value) { '31-02-2010' }

        it 'should raise exception' do
          expect { subject }.to raise_exception ActiveRecord::RecordInvalid,
                                                "Validation failed: Value in data.#{name}.value incorrect date format"
        end
      end
    end

    context 'when parameter is group' do
      let(:value_type) { 'group' }
      let(:name) { 'test_group' }
      let(:value) { [] }
      let(:label) { 'test_group' }

      it 'should add parameter' do
        expect(subject).to be_valid
      end
    end

    context 'when parameter is ref' do
      let(:value_type) { 'ref' }
      let(:name) { 'test_ref' }
      let(:value) { [] }
      let(:label) { 'test_ref' }

      it 'should add parameter' do
        expect(subject).to be_valid
      end
    end
  end

  context '.add_by_path' do
    let(:value_type) { 'group' }
    let(:name) { 'test_group' }
    let(:value) { [] }
    let(:label) { 'test_group' }
    subject { Outsoft::Params.add_by_path path: path, name: name, value_type: value_type, value: value, label: label }

    before do
      DatabaseCleaner.start
      Outsoft::Param.create name: 'group1', data: { group1: { value_type: 'group', label: 'group1', value: {} } }
      group2 = Outsoft::Param.create name: 'group2', data: { group2: { value_type: 'group', label: 'group1', value: {} } }
      group2.data['group2']['value']['nested_group'] = { 'value_type' => 'group', 'label' => 'nested_group', 'value' => {} }
      group2.data['group2']['value']['nested_group']['value']['deeply_nested_group'] =
        { 'value_type' => 'group', 'label' => 'deeply_nested_group', 'value' => {} }
      group2.save!
      group3 = Outsoft::Param.create name: 'group3', data: { group3: { value_type: 'group', label: 'group1', value: {} } }
      group3.data['group3']['value']['nested_simple_value'] =
        { 'value_type' => 'int', 'label' => 'Nested simple value', 'value' => 10 }
      group3.save!
      Outsoft::Param.create name: 'ref', data: { ref: { value_type: 'ref', label: 'ref', value: {} } }
    end

    after do
      DatabaseCleaner.clean
    end

    context 'when path is nil' do
      let(:path) { nil }

      it 'should raise exception' do
        expect { subject }.to raise_exception 'Incorrect path'
      end
    end

    context 'when path is not a string' do
      let(:path) { 1 }

      it 'should raise exception' do
        expect { subject }.to raise_exception 'Incorrect path'
      end
    end

    context 'when path doesnot exists' do
      let(:path) { 'thispath.really.doesnot.exists.in.database' }

      it 'should raise exception' do
        expect { subject }.to raise_exception "Undefined params by path #{path}"
      end
    end

    context 'when add simple type to group' do
      let(:value_type) { 'string' }
      let(:name) { 'pet name' }
      let(:value) { 'dog1' }
      let(:label) { 'pet' }
      let(:path) { 'group1' }

      it 'should add param' do
        expect subject
      end
    end

    context 'when add ref to group' do
      let(:value_type) { 'ref' }
      let(:name) { 'pets' }
      let(:value) { {} }
      let(:label) { 'pets' }
      let(:path) { 'group2' }

      it 'should add param' do
        expect subject
      end
    end

    context 'when add group to group' do
      let(:value_type) { 'group' }
      let(:name) { 'pets' }
      let(:value) { {} }
      let(:label) { 'pets' }
      let(:path) { 'group1' }

      it 'should add param' do
        expect subject
      end
    end

    context 'when add value to nested group' do
      let(:value_type) { 'int' }
      let(:name) { 'cats' }
      let(:value) { 1 }
      let(:label) { 'cat' }
      let(:path) { 'group2.nested_group' }

      it 'should add param' do
        expect subject
      end
    end

    context 'when add value to nested group' do
      let(:value_type) { 'int' }
      let(:name) { 'cats' }
      let(:value) { 1 }
      let(:label) { 'cat' }
      let(:path) { 'group2.nested_group.deeply_nested_group' }

      it 'should add param' do
        expect subject
      end
    end

    context 'when add value with exists path in nested group' do
      let(:value_type) { 'group' }
      let(:name) { 'nested_group' }
      let(:value) { {} }
      let(:label) { 'new nestaed group' }
      let(:path) { 'group2' }

      it 'should raise exception' do
        expect { subject }.to raise_exception "#{name} param already exists in #{path}"
      end
    end

    context 'when add simple value to ref' do
      let(:value_type) { 'string' }
      let(:name) { 'ref_value_1' }
      let(:value) { 'Value' }
      let(:label) { 'Reference Table value' }
      let(:path) { 'ref' }

      it 'should add param' do
        expect subject
      end
    end

    context 'when add ref to ref' do
      let(:value_type) { 'ref' }
      let(:name) { 'nested_ref' }
      let(:value) { {} }
      let(:label) { 'Nested Reference Table value' }
      let(:path) { 'ref' }

      it 'should raise exception' do
        expect { subject }.to raise_exception ActiveRecord::RecordInvalid, 'Validation failed: Value data.ref.value ref can contain only simple values'
      end
    end

    context 'when add group to ref' do
      let(:value_type) { 'group' }
      let(:name) { 'nested_group' }
      let(:value) { {} }
      let(:label) { 'Nested Group value' }
      let(:path) { 'ref' }

      it 'should raise exception' do
        expect { subject }.to raise_exception ActiveRecord::RecordInvalid, 'Validation failed: Value data.ref.value ref can contain only simple values'
      end
    end

    context 'when add group to simple value' do
      let(:value_type) { 'group' }
      let(:name) { 'nested_group' }
      let(:value) { {} }
      let(:label) { 'Nested Group Table value' }
      let(:path) { 'group3.nested_simple_value' }

      it 'should raise exception' do
        expect { subject }.to raise_exception 'You can add nested params only inside ref and group'
      end
    end
  end
end
