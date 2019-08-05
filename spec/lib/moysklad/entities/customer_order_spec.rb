require 'spec_helper'

describe Moysklad::Entities::CustomerOrder do
  context 'generate' do
    subject {
      p= Moysklad::Entities::CustomerOrderPosition.new
      p.vat = 18
      p.price = Moysklad::Entities::Price.new
      p.price.value = 123
      p.reserve = 123

      co = Moysklad::Entities::CustomerOrder.new
      co.sum = Moysklad::Entities::Price.new
      co.sum.value = 456
      co.description = 'Описание'
      co.customerOrderPosition = p
      co
    }

    it 'state' do
      stub_rest 'Workflow', :list, 0
      allow(subject).to receive(:stateUuid).and_return 'f16b0ca9-ff79-11e4-90a2-8ecb0000fdf9'
      expect(subject.state universe).to be_a Moysklad::Entities::WorkflowState
    end

    it 'to_xml' do
      expect(subject.to_xml).to be_a String
    end

    it 'to_s' do
      expect(subject.to_s).to be_a String
    end

    it 'include xml' do
      expect(subject.to_xml).to include '<?xml version="1.0" encoding="utf-8"?>'
    end

    it 'include customerOrder' do
      expect(subject.to_xml).to include "<customerOrder"
    end

    it 'include customerOrderPosition' do
      expect(subject.to_xml).to include "<customerOrderPosition"
    end
  end

  context 'parse' do
    subject { Moysklad::Entities::CustomerOrder.parse File.read './spec/fixtures/customer_order.xml' }

    it 'include customerOrder' do
      expect(subject.to_xml).to include "<customerOrder"
    end

    it 'include customerOrderPosition' do
      expect(subject.to_xml).to include "<customerOrderPosition"
    end
  end
end
