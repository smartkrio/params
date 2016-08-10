require 'spec_helper'

describe Outsoft::Params do
  context '.remove' do
    let(:wrap_name) { 'group1' }
    let(:path) { wrap_name }
    let(:check_record) { Outsoft::Param.find_by(name: wrap_name) }

    subject { Outsoft::Params.remove(path: path) }

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

    context 'when remove root level param' do
      it 'should remove root level param' do
        expect(subject)
        expect(check_record).to eq nil
      end
    end

    context 'when remove nested param' do
      let(:wrap_name) { 'group2' }
      let(:path) { "#{wrap_name}.nested_group" }

      it 'should remove nested level param' do
        expect(subject)
        expect(check_record.data[wrap_name]['value']).to_not have_key 'nested_group'
      end
    end

    context 'when param undefined' do
      let(:path) { 'unexists.path' }

      it 'should raise exception' do
        expect { subject }.to raise_exception "Undefined params by path #{path}"
      end
    end
  end
end
