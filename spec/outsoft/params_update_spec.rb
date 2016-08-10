require 'spec_helper'

describe Outsoft::Params do
  context '.update' do
    let(:name) { nil }
    let(:value_type) { nil }
    let(:value) { nil }
    let(:label) { nil }
    let(:company_id) { nil }
    let(:wrap_name) { 'group3' }
    let(:path) { "#{wrap_name}.nested_simple_value" }
    let(:check_record) { Outsoft::Param.find_by(name: wrap_name) }

    subject { Outsoft::Params.update(path: path, value_type: value_type, value: value, label: label, name: name, company_id: company_id) }

    before(:each) do
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
      Outsoft::Param.create name: 'children_count', data: { children_count: { value_type: 'int', label: 'Children count', value: 1 } }
      group4 = Outsoft::Param.create name: 'group4', data: { group4: { value_type: 'group', label: 'group1', value: {} } }
      group4.data['group4']['value']['nested_simple_value'] =
        { 'value_type' => 'int', 'label' => 'Nested simple value', 'value' => 10 }
      group4.save!
      Outsoft::Param.create name: 'simple_value', data: { simple_value: { value_type: 'int', label: 'Some counter', value: 1 } }
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    context 'when param undefined' do
      let(:path) { 'unexists.path' }

      it 'should raise exception' do
        expect { subject }.to raise_exception "Undefined params by path #{path}"
      end
    end

    context 'when company_id present' do
      let(:company_id) { 1 }

      it 'should update company_id' do
        expect(subject)
        expect(check_record.company_id).to eq company_id
      end
    end

    context 'when update name in root level' do
      let(:name) { 'new_name' }
      let(:wrap_name) { 'new_name' }
      let(:path) { 'group3' }

      it 'should update name in root level and in json' do
        expect subject
        expect(check_record.name).to eq name
        expect(check_record.data).to have_key name
      end
    end

    context 'when update simple value' do
      let(:value) { 10 }
      let(:path) { 'children_count' }
      let(:wrap_name) { 'children_count' }
      let(:path) { 'children_count' }

      it 'should update value in root level' do
        expect subject
        expect(check_record.data[wrap_name]['value']).to eq value
      end
    end

    context 'when change root label' do
      let(:label) { 'New label' }
      let(:path) { 'children_count' }
      let(:wrap_name) { 'children_count' }
      let(:path) { 'children_count' }

      it 'should update label in root level' do
        expect subject
        expect(check_record.data[wrap_name]['label']).to eq label
      end
    end

    context 'when change nested label' do
      let(:label) { 'New label' }
      let(:path) { 'group2.nested_group' }
      let(:wrap_name) { 'group2' }
      let(:path) { 'group2.nested_group' }

      it 'should update label in nested json level' do
        expect subject
        expect(check_record.data[wrap_name]['value']['nested_group']['label']).to eq label
      end
    end

    context 'when update nested simple value' do
      let(:value) { 10 }
      let(:wrap_name) { 'group4' }
      let(:path) { "#{wrap_name}.nested_simple_value" }

      it 'should update value in nested json level' do
        expect subject
        expect(check_record.data[wrap_name]['value']['nested_simple_value']['value']).to eq value
      end
    end

    context 'when change simple type to simple type' do
      let(:value_type) { 'string' }
      let(:wrap_name) { 'simple_value' }
      let(:path) { wrap_name }
      let(:value) { 'new_simple_value' }

      it 'should update simple type and value to other simple type and value' do
        expect subject
        expect(check_record.data[wrap_name]['value_type']).to eq value_type
        expect(check_record.data[wrap_name]['value']).to eq value
      end
    end

    context 'when change simple value to group' do
      let(:value_type) { 'group' }
      let(:wrap_name) { 'group4' }
      let(:path) { "#{wrap_name}.nested_simple_value" }

      it 'should update simple type to group type' do
        expect subject
        expect(check_record.data[wrap_name]['value']['nested_simple_value']['value_type']).to eq value_type
        expect(check_record.data[wrap_name]['value']['nested_simple_value']['value']).to eq({})
      end
    end

    context 'when change simple value to ref' do
      let(:value_type) { 'group' }
      let(:wrap_name) { 'ref' }
      let(:path) { wrap_name }

      it 'should update simple type to ref type' do
        expect subject
        expect(check_record.data[wrap_name]['value_type']).to eq value_type
        expect(check_record.data[wrap_name]['value']).to eq({})
      end
    end

    context 'when change group to simple value' do
      let(:value_type) { 'int' }
      let(:wrap_name) { 'group1' }
      let(:path) { wrap_name }

      it 'should update group to simple type' do
        expect subject
        expect(check_record.data[wrap_name]['value_type']).to eq value_type
        expect(check_record.data[wrap_name]['value']).to eq 0
      end
    end

    context 'when change ref to simple value' do
      let(:value_type) { 'string' }
      let(:wrap_name) { 'ref' }
      let(:path) { wrap_name }

      it 'should update ref to simple type' do
        expect subject
        expect(check_record.data[wrap_name]['value_type']).to eq value_type
        expect(check_record.data[wrap_name]['value']).to eq 'n/a'
      end
    end
  end
end
