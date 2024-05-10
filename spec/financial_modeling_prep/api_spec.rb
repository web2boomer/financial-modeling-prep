# frozen_string_literal: true

require "financial_modeling_prep"

RSpec.describe FinancialModelingPrep::API do

  let(:api) { described_class.new('03341a8e04942af8cca7ded0670758b0') }

  describe '#search' do
    subject { api.search(query: "AAPL")}

    it "includes attributes" do  
      # expect(subject.keys).to include ["symbol"]
      expect(subject.count).to be > 0
    end

  end

end
