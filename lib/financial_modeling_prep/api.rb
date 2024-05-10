require 'json'
require 'logger'
require 'faraday'

module FinancialModelingPrep
  class API
    HOST = "https://financialmodelingprep.com/api/v3"
    
    JSON_CONTENT_TYPE = 'application/json'

    RETRY_WAIT = 10
    MAX_RETRY = 5    

    def initialize(apikey = ENV['FINANCIAL_MODELING_PREP_API_KEY'] )
      @apikey = apikey # fall back on ENV var if non passed in
    end

    # beginning of endpoints, note that there are inconsistencies with some endpoints using hyphens and some underscores. To make this more obvious, hypens are strings.

    def search(query:)
      request :search, {query: query}
    end

    def search_ticker(query:)
      request "search-ticker", {query: query}
    end

    def search_name(query:)
      request "search-name", {query: query}
    end    

    def earnings_calendar(from:, to:)
      request :earning_calendar, {from: from, to: to}
    end

    def earning_call_transcript(ticker:, year:, quarter:)
      request "earning_call_transcript/#{ticker}", {year: year, quarter: quarter}
    end    
        

    private

      def request(endpoint, args)
        retries = 0

        args[:apikey] = @apikey # add in API key

        # endpoint = endpoint.to_s.gsub('_', '-')

        begin
          full_endpoint_url = "#{HOST}/#{endpoint}"
          response = Faraday.get full_endpoint_url, args
          
          # puts "Args => #{args}"
          # puts "Status => #{response.status}"
          # puts "Headers => #{response.headers}"
          # puts "Body => #{response.body}"
          # params = {book: {title: "foo", author: "bar"}} 
          # headers = {Content-Type: 'application/json'}          

          puts response.body

          if response.status == 403 || response.status == 401
            raise AccessDenied.new response.body

          elsif response.status != 200
            raise ServiceUnavailable.new "#{response.status} #{response.body['Error Message']}"

          elsif !response.headers['content-type'].include? JSON_CONTENT_TYPE
            raise InvalidResponse.new response.body

          elsif response.success?
            return JSON.parse response.body

          else
            raise Error.new response.body
          end




        rescue ServiceUnavailable => exception

          if retries < MAX_RETRY
            logger.debug("Service unavailable due to #{exception.message}, retrying...")
            retries += 1
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

