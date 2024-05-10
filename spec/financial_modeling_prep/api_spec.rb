# frozen_string_literal: true

require "financial_modeling_prep"

RSpec.describe FinancialModelingPrep::API do

  let(:api) { described_class.new('03341a8e04942af8cca7ded0670758b0') }

  describe '#search' do
    subject { api.search(query: "Apple") }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end

  describe '#search_ticker' do
    subject { api.search_ticker(query: "META") }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end

  describe '#search_name' do
    subject { api.search_name(query: "Microsoft") }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end

  describe '#earnings_calendar' do
    subject { api.earnings_calendar(from: '2024-05-01', to: '2024-05-10') }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end  



end
