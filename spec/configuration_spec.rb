require 'spec_helper'

RSpec.describe JsonapiSwaggerHelpers::Configuration do
  let(:instance) { described_class.new }

  describe 'customizing type mapping' do
    it 'mutates correctly' do
      instance.type_mapping[:string] << 'new!'
      expect(instance.type_mapping[:string]).to include('new!')
    end
  end
end
