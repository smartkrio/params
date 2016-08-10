require 'spec_helper'

describe Outsoft::Params do
  context '.get' do
    let(:path) { 'group1' }
    subject { Outsoft::Params.get(path: path) }

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

      ref = Outsoft::Param.create name: 'ref', data: { ref: { value_type: 'ref', label: 'ref', value: {} } }
      ref.data['ref']['value']['param1'] =  { 'value_type' => 'int', 'label' => 'Ref simple value 1', 'value' => 1 }
      ref.data['ref']['value']['param2'] =  { 'value_type' => 'int', 'label' => 'Ref simple value 2', 'value' => 2 }
      ref.data['ref']['value']['param3'] =  { 'value_type' => 'int', 'label' => 'Ref simple value 3', 'value' => 3 }
      ref.data['ref']['value']['param4'] =  { 'value_type' => 'int', 'label' => 'Ref simple value 4', 'value' => 4 }
      ref.save!

      Outsoft::Param.create name: 'children_count', data: { children_count: { value_type: 'int', label: 'Children count', value: 1 } }
      group4 = Outsoft::Param.create name: 'group4', data: { group4: { value_type: 'group', label: 'group1', value: {} } }
      group4.data['group4']['value']['nested_simple_value'] =
        { 'value_type' => 'int', 'label' => 'Nested simple value', 'value' => 10 }
      group4.save!
      Outsoft::Param.create name: 'simple_value', data: { simple_value: { value_type: 'int', label: 'Some counter', value: 1 } }

      group5 = Outsoft::Param.create name: 'group5', data: { group5: { value_type: 'group', label: 'group5', value: {} } }
      group5.data['group5']['value']['ref'] = { 'value_type' => 'ref', 'label' => 'Nested ref', 'value' => {} }
      nested_ref = group5.data['group5']['value']['ref']['value']
      nested_ref['param1'] =  { 'value_type' => 'int', 'label' => 'Nested ref simple value 1', 'value' => 1 }
      nested_ref['param2'] =  { 'value_type' => 'int', 'label' => 'Nested ref simple value 2', 'value' => 2 }
      nested_ref['param3'] =  { 'value_type' => 'int', 'label' => 'Nested ref simple value 3', 'value' => 3 }
      nested_ref['param4'] =  { 'value_type' => 'int', 'label' => 'Nested ref simple value 4', 'value' => 4 }
      group5.save!
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    context 'when path unexists' do
      let(:path) { 'unexists.path' }

      it 'should raise exception' do
        expect { subject }.to raise_exception "Undefined params by path #{path}"
      end
    end

    context 'when get simple value' do
      context 'when root param' do
        let(:path) { 'simple_value' }

        it 'should return param' do
          expect(subject.size).to eq 1
          first_param = subject.first
          expect(first_param['value']).to eq 1
          expect(first_param['label']).to eq 'Some counter'
          expect(first_param['value_type']).to eq 'int'
          expect(first_param['name']).to eq 'simple_value'
        end
      end

      context 'when get simple nested param from group' do
        let(:path) { 'group3.nested_simple_value' }

        it 'should return param' do
          expect(subject.size).to eq 1
          first_param = subject.first
          expect(first_param['value']).to eq 10
          expect(first_param['label']).to eq 'Nested simple value'
          expect(first_param['value_type']).to eq 'int'
          expect(first_param['name']).to eq 'nested_simple_value'
        end
      end

      context 'when get simple nested param from ref' do
        let(:path) { 'ref.param1' }

        it 'should return param' do
          expect(subject.size).to eq 1
          first_param = subject.first
          expect(first_param['value']).to eq 1
          expect(first_param['label']).to eq 'Ref simple value 1'
          expect(first_param['value_type']).to eq 'int'
          expect(first_param['name']).to eq 'param1'
        end
      end

      context 'when get group like simple param' do
        let(:path) { 'group3' }
        it 'should raise exception' do
          expect { subject.size }.to raise_exception 'Can\'t get simple value by group3, because it\'s group'
        end
      end

      context 'when get ref like simple param' do
        let(:path) { 'ref' }
        it 'should raise exception' do
          expect { subject.size }.to raise_exception 'Can\'t get simple value by ref, because it\'s ref'
        end
      end
    end

    context 'when path has `*`' do
      context 'when path equal *' do
        let(:path) { '*' }

        it 'should raise exception' do
          expect { subject }.to raise_exception 'Path can\'t be *'
        end
      end

      context 'when try get not ref data' do
        let(:path) { 'group2.*' }
        it 'should raise exception' do
          expect { subject.size }.to raise_exception 'Can\'t get * values not from ref'
        end
      end

      context 'when try get root ref data' do
        let(:path) { 'ref.*' }
        it 'should get params' do
          expect(subject.size).to eq 4
          second_param = subject[1]
          expect(second_param['value']).to eq 2
          expect(second_param['label']).to eq 'Ref simple value 2'
          expect(second_param['value_type']).to eq 'int'
          expect(second_param['name']).to eq 'param2'
        end
      end

      context 'when try get nested ref data' do
        let(:path) { 'group5.ref.*' }
        it 'should get params' do
          expect(subject.size).to eq 4
          second_param = subject[1]
          expect(second_param['value']).to eq 2
          expect(second_param['label']).to eq 'Nested ref simple value 2'
          expect(second_param['value_type']).to eq 'int'
          expect(second_param['name']).to eq 'param2'
        end
      end
    end
  end
end
