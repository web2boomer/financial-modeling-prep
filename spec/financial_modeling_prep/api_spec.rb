# frozen_string_literal: true

require "financial_modeling_prep"

RSpec.describe FinancialModelingPrep::API do

  let(:api) { described_class.new }

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

  describe '#profile' do
    subject { api.profile(symbol: "AAPL") }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end


  describe '#company_core_info' do
    subject { api.company_core_info(symbol: "AAPL") }

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

  describe '#earning_calendar_confirmed' do
    subject { api.earning_calendar_confirmed(from: '2024-02-01', to: '2024-05-10') }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end   

  describe '#earning_call_transcript' do
    subject { api.earning_call_transcript(symbol: 'AAPL', year: '2024', quarter: '1') }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end  

  describe '#press_releases' do
    subject { api.press_releases(symbol: 'AAPL') }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end    

  describe '#sec_filings' do
    subject { api.sec_filings(symbol: 'AAPL') }

    it "includes attributes" do  
      expect(subject.count).to be > 0
    end
  end  

end
