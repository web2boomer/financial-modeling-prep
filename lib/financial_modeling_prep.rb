require_relative "financial_modeling_prep/version"
require_relative "financial_modeling_prep/api"

module FinancialModelingPrep
  class Error < StandardError; end
  class AccessDenied < Error; end
  class ServiceUnavailable < Error; end
  class InvalidResponse < Error; end
end
