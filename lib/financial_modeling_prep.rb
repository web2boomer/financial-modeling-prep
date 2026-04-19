require_relative "financial_modeling_prep/version"

module FinancialModelingPrep
  class Error < StandardError; end
  class AccessDenied < Error; end

  class ServiceUnavailable < Error
    attr_reader :http_status, :retry_after

    def initialize(message, http_status: nil, retry_after: nil)
      super(message)
      @http_status = http_status
      @retry_after = retry_after
    end
  end

  class InvalidResponse < Error; end
end

require_relative "financial_modeling_prep/api"
