require 'json'
require 'logger'
require 'faraday'

module FinancialModelingPrep
  class API
    HOST = "https://financialmodelingprep.com/api/"
    
    JSON_CONTENT_TYPE = 'application/json'

    RETRY_WAIT = 10
    MAX_RETRY = 6    

    def initialize(apikey = ENV['FINANCIAL_MODELING_PREP_API_KEY'] )
      @apikey = apikey # fall back on ENV var if non passed in
    end

    # beginning of endpoints, note that there are inconsistencies with some endpoints using hyphens and some underscores. To make this more obvious, hypens are strings.

    def search(query:)
      request :search, {query: query}
    end

    def search_ticker(query:)
      request "v3/search-ticker", {query: query}
    end

    def search_name(query:)
      request "v3/search-name", {query: query}
    end    

    def search_name(query:)
      request "v3/search-name", {query: query}
    end    
    
    def profile(symbol:)
      request "v3/profile/#{symbol}"
    end      

    def earnings_calendar(from:, to:)
      request :earning_calendar, {from: from, to: to}
    end

    def earning_call_transcript(symbol:, year: nil, quarter: nil)
      request "v3/earning_call_transcript/#{symbol}", {year: year, quarter: quarter} 
    end   
    
    def earning_call_dates(symbol:, year: nil, quarter: nil)
      request "v4/earning_call_transcript", {symbol: symbol} # note v4 of API
    end       
        
    def sec_filings(symbol: nil, type: nil, page: nil)
      if symbol
        request "v3/sec_filings/#{symbol}", {type: type, page: page} 
      else
        request "v3/rss_feed", {page: 0} 
      end
    end        

    private

      def request(endpoint, args = Hash.new)
        retries = 0

        args[:apikey] = @apikey # add in API key

        begin
          full_endpoint_url = "#{HOST}#{endpoint}"
          puts full_endpoint_url
          response = Faraday.get full_endpoint_url, args
          
          # logger.debug response.status
          # logger.debug response.body

          if response.status == 403 || response.status == 401
            raise AccessDenied.new response.body

          elsif response.status != 200
            error_message = JSON.parse response.body
            raise ServiceUnavailable.new "#{response.status} #{error_message["Error Message"]}"

          elsif !response.headers['content-type'].include? JSON_CONTENT_TYPE
            raise InvalidResponse.new response.body

          elsif response.success?
            return JSON.parse response.body

          else
            raise Error.new response.body
          end




        rescue ServiceUnavailable => exception

          if retries < MAX_RETRY
            retries += 1
            logger.info("Service unavailable due to #{exception.message}, retrying (attempt #{retries} of #{MAX_RETRY})...")
            sleep RETRY_WAIT
            retry
          else
            raise exception
          end
        end
      end


      def logger
        @logger ||= Logger.new(STDOUT)
      end

  end
end

