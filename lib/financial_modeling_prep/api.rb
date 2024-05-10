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


    def search(query:)
      request :search, {query: query}
    end

    def search_ticker(query:)
      request :search_ticker, {query: query}
    end

    def search_name(query:)
      request :search_name, {query: query}
    end    

    def earnings_calendar(from:, to:)
      request :earnings_calendar, {from: from, to: to}
    end
        

    private

      def request(endpoint, args)
        retries = 0

        args[:apikey] = @apikey # add in API key

        endpoint = endpoint.to_s.gsub('_', '-')

        begin
          response = Faraday.get "#{HOST}/#{endpoint}", args
          
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

