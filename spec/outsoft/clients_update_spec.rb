require 'spec_helper'

describe Outsoft::Clients do
  context '.update' do
    let(:unexsist_id) { 123_123_432 }

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

      Outsoft::Clients.create data: { id: 1 }
      Outsoft::Clients.create data: { id: 2, extra: [['exists_param', 'some value']] }
      unexists_client = Outsoft::Client.find_by id: unexsist_id
      unexists_client.delete if unexists_client.present?
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    let(:id) { 1 }
    let(:predefined) { nil }
    let(:extra) { nil }
    let(:check_value) { Outsoft::Client.find id }

    subject { Outsoft::Clients.update id: id, predefined: predefined, extra: extra }

    context 'when client does not exists' do
      let(:id) { unexsist_id }

      it 'should raise exception' do
        expect { subject }.to raise_exception ActiveRecord::RecordNotFound,
                                              "Couldn't find Outsoft::Client with 'id'=#{unexsist_id}"
      end
    end

    context 'extra present' do
      context 'extra empty' do
        let(:extra) { [] }

        it 'should do nothing' do
          expect subject
        end
      end

      context 'add extra as correct hash' do
        let(:extra) { [['some_param1', 'some value 1'], ['some_param2', 'some value 2']] }

        it 'should add extra' do
          expect(subject)
          expect(check_value.extra).to eq extra
        end
      end

      context 'update exists extra' do
        let(:id) { 2 }
        let(:extra) { [['some_new_param', 'some new param']] }

        it 'should update extra' do
          expect(subject)
          expect(check_value.extra).to eq extra
        end
      end

      context 'when add incorrect extra' do
        context 'when extra is not an array' do
          let(:extra) { 1 }

          it 'should raise exception' do
            expect { subject }.to raise_exception 'Extra must be an Array'
          end
        end
      end
    end

    context 'when predefined present' do
      context 'when predefined is empty' do
        let(:predefined) { [] }

        it 'should make nothing' do
          expect(subject)
        end
      end

      context 'when predefined is not an array' do
        let(:predefined) { 'some string' }

        it 'should raise exception' do
          expect { subject }.to raise_exception 'Predefined must be an Array'
        end
      end

      context 'when path does not exists' do
        let(:predefined) { [{ 'path' => 'not.exists.path', 'value' => '23423' }] }

        it 'should raise exception' do
          expect { subject }.to raise_exception 'Undefined params by path not.exists.path'
        end
      end

      context 'when has not path' do
        let(:predefined) { [{ 'value' => '23423' }] }

        it 'should raise exception' do
          expect { subject }.to raise_exception 'Predefined must contain items with `path` and `value`'
        end
      end

      context 'when has not value' do
        let(:predefined) { [{ 'path' => 'some_path' }] }

        it 'should raise exception' do
          expect { subject }.to raise_exception 'Predefined must contain items with `path` and `value`'
        end
      end

      context 'when update several params' do
        let(:predefined) do
          [
            { 'path' => 'simple_value', 'value' => 10 },
            { 'path' => 'group3.nested_simple_value', 'value' => 11 }
          ]
        end

        it 'should update data' do
          expect(subject)
          expect(check_value.predefined['simple_value']['value']).to eq 10
          expect(check_value.predefined['group3']['value']['nested_simple_value']['value']).to eq 11
        end
      end

      context 'when set incorrect value for type' do
        let(:predefined) do
          [{ 'path' => 'simple_value', 'value' => 'wed' }]
        end

        it 'should raise exception' do
          expect { subject }.to raise_exception ActiveRecord::RecordInvalid,
                                                'Validation failed: Value In simple_value.value value must be integer'
        end
      end
    end
  end
end
