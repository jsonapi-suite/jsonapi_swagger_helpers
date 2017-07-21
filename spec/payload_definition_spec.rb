require 'spec_helper'

RSpec.describe JsonapiSwaggerHelpers::PayloadDefinition do
  describe '.swagger_type_for' do
    it 'finds the corresponding swagger type' do
      mapped = described_class.swagger_type_for(:foo, 'myattr', String)
      expect(mapped).to eq(:string)
    end

    context 'when no type specified' do
      it 'defaults to string' do
        mapped = described_class.swagger_type_for(:foo, 'myattr', nil)
        expect(mapped).to eq(:string)
      end
    end

    context 'when the payload key has multiple types' do
      it 'returns the first matching type' do
        mapped = described_class
          .swagger_type_for(:foo, 'myattr', [Bignum, Float])
        expect(mapped).to eq(:integer)
      end
    end

    context 'when no corresponding type found' do
      it 'raises an error' do
        expect {
          described_class.swagger_type_for(:foo, 'myattr', NilClass)
        }.to raise_error(JsonapiSwaggerHelpers::Errors::TypeNotFound)
      end
    end
  end
end
