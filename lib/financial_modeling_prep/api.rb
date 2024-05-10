require 'json'
require 'logger'
require 'faraday'

module FinancialModelingPrep
  class API
    HOST = "https://financialmodelingprep.com/api/v3"
    
    JSON_CONTENT_TYPE = 'application/json'

    RETRY_WAIT = 10
    MAX_RETRY = 5    

    def initialize(apikey)
      @apikey = apikey
    end


    def search(query:)
      request :search, {query: query}
    end

        

    private

      def request(endpoint, args)
        retries = 0

        args[:apikey] = @apikey # add in API key

        begin
          response = Faraday.get "#{HOST}/#{endpoint}", args
          
          puts "Args => #{args}"
          puts "Status => #{response.status}"
          puts "Headers => #{response.headers}"
          puts "Body => #{response.body}"
          # params = {book: {title: "foo", author: "bar"}} 
          # headers = {Content-Type: 'application/json'}          

          if response.status != 200
            raise ServiceUnavailable.new "#{response.status} #{response.body}"

          elsif !response.headers['content-type'].include? JSON_CONTENT_TYPE
            raise InvalidResponse.new response.body

          elsif response.success?
            return JSON.parse response.body

          else
            raise Error.new response.body
          end




        rescue ServiceUnavailable => exception

          if retries < MAX_RETRY
            logger.debug('Service unavailable, retrying...')
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

