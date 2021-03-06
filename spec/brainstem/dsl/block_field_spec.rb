require 'spec_helper'
require 'brainstem/dsl/block_field'

describe Brainstem::DSL::BlockField do
  let(:name)         { :tasks }
  let(:type)         { :hash }
  let(:description)  { 'the title of this model' }
  let(:options)      { { info: description } }
  let(:nested_field) { Brainstem::DSL::BlockField.new(name, type, options) }
  let(:model)        { Workspace.find(1) }

  describe 'configuration' do
    context 'when parent field specified' do
      let(:parent_field) { Brainstem::DSL::BlockField.new(name, type, options) }
      let(:nested_field) { Brainstem::DSL::BlockField.new(name, type, options, parent_field) }
      let(:inherited_field) do
        Brainstem::DSL::Field.new(:parent_name, type, dynamic: -> (model) { model.parent.try(:name) })
      end
      let(:overriden_field) do
        Brainstem::DSL::Field.new(:name, type, dynamic: -> (model) { "Formatted #{model.name}" })
      end

      before do
        parent_field.configuration[:name] = Brainstem::DSL::Field.new(:name, type, {})
        parent_field.configuration[:parent_name] = inherited_field

        nested_field.configuration[:name] = overriden_field
        nested_field.configuration[:parent_title] = Brainstem::DSL::Field.new(:parent_title, type,
          dynamic: -> (model) { model.parent.try(:name) }
        )

        expect(nested_field.configuration.keys).to include('name', 'parent_title')
      end

      it 'inherits sub fields from the parent field' do
        expect(nested_field.configuration.keys).to include('parent_name')
        expect(nested_field.configuration[:parent_name]).to eq(inherited_field)
      end

      it 'override keys inherits from the parent' do
        expect(nested_field.configuration.keys).to include('name')
        expect(nested_field.configuration[:name]).to eq(overriden_field)
      end
    end

    context 'when parent field is not specified' do
      let(:nested_field) { Brainstem::DSL::BlockField.new(name, type, options) }

      before do
        nested_field.configuration[:name] = Brainstem::DSL::Field.new(:name, type, {})
        nested_field.configuration[:parent_title] = Brainstem::DSL::Field.new(:parent_title, type,
          dynamic: -> (model) { model.parent.try(:name) }
        )
      end

      it 'only has sub fields defined on itself' do
        expect(nested_field.configuration.keys).to match_array(['name', 'parent_title'])
      end
    end
  end

  describe 'self.for' do
    subject { described_class.for(name, type, options) }

    context 'when given an array type' do
      let(:type) { :array }

      it 'returns a new ArrayBlockField' do
        expect(subject).to be_instance_of(Brainstem::DSL::ArrayBlockField)
      end
    end

    context 'when given a hash type' do
      let(:type) { :hash }

      it 'returns a new HashBlockField' do
        expect(subject).to be_instance_of(Brainstem::DSL::HashBlockField)
      end
    end

    context 'when given an unknown type' do
      let(:type) { :unknown }

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end

  describe 'evaluate_value_on' do
    let(:context) { {} }
    let(:helper_instance) { Object.new }

    context 'when lookup option is specifed' do
      let(:context) {
        {
          lookup: Brainstem::Presenter.new.send(:empty_lookup_cache, [name.to_s], []),
          models: [model]
        }
      }

      context 'when lookup_fetch option is not specified' do
        let(:options) do
          { lookup: lambda { |models| Hash[models.map { |model| [model.id, model.tasks.to_a] }] } }
        end

        before do
          expect(options).to_not have_key(:lookup_fetch)
        end

        it 'returns the value from the lookup cache' do
          expect(nested_field.evaluate_value_on(model, context, helper_instance)).to eq(model.tasks.to_a)
        end
      end

      context 'when lookup_fetch option is specified' do
        let(:options) do
          {
            lookup: lambda { |models| Hash[models.map { |model| [model.id + 10, model.tasks.to_a] }] },
            lookup_fetch: lambda { |lookup, model| lookup[model.id + 10]  }
          }
        end

        before do
          expect(options).to have_key(:lookup_fetch)
        end

        it 'returns the value from the lookup cache using the lookup fetch' do
          expect(nested_field.evaluate_value_on(model, context, helper_instance)).to eq(model.tasks.to_a)
        end
      end
    end

    context 'when dynamic option is specified' do
      let(:options) { { dynamic: lambda { |model| model.tasks.to_a } } }

      it 'calls the :dynamic lambda in the context of the given instance' do
        expect(nested_field.evaluate_value_on(model, context, helper_instance)).to eq(model.tasks.to_a)
      end
    end

    context 'when via option is specified' do
      let(:options) { { via: :tasks } }

      it 'calls the method name in the :via option in the context of the given instance' do
        expect(nested_field.evaluate_value_on(model, context, helper_instance)).to eq(model.tasks.to_a)
      end
    end

    context 'when none of the options are specified' do
      let(:options) { {} }

      it 'should raise error' do
        expect {
          nested_field.evaluate_value_on(model, context, helper_instance)
        }.to raise_error(StandardError)
      end
    end
  end

  describe 'use_parent_value?' do
    let(:field) { Brainstem::DSL::Field.new(:type, type, options) }

    subject { nested_field.use_parent_value?(field) }

    context 'when sub field does not specify use_parent_value option' do
      let(:options) { { info: description } }

      it { is_expected.to be_truthy }
    end

    context 'when sub field specifies use_parent_value option' do
      let(:options) { { use_parent_value: use_parent_value } }

      context 'when set to true' do
        let(:use_parent_value) { true }

        it { is_expected.to be_truthy }
      end

      context 'when set to false' do
        let(:use_parent_value) { false }

        it { is_expected.to be_falsey }
      end
    end
  end
end
