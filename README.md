# financial-modeling-prep 

[Financial Modeling Prep](https://site.financialmodelingprep.com/developer/docs) API wrapper for Ruby

You can grab your [API key here](https://site.financialmodelingprep.com/developer/docs/dashboard)

## Installation

Install the gem and add to the application's Gemfile by executing:

```
$ bundle add financial-modeling-prep
```

If bundler is not being used to manage dependencies, install the gem by executing:

```
$ gem install financial-modeling-prep 
```

## Usage


### Inference API

Financial Modeling Prep provides a ton of API end points from company search to financial statements to SEC filings to earnings transcripts. 

```ruby
require "financial_modeling_prep"
```

First instantiate a FinanceModelingPrep API client:

```ruby
fmp = FinancialModelingPrep::API.new(ENV['YOUR_FINANCIAL_MODELING_PREP_TOKEN'])
```

You can also set the API FINANCIAL_MODELING_PREP_API_KEY and then just call

```ruby
fmp = FinancialModelingPrep::API.new
```

Now we can do all sorts...

(Company Search)[https://site.financialmodelingprep.com/developer/docs#company-search]

```ruby
companies = fmp.search(query: 'Apple')
companies = fmp.search_ticker(query: 'AA')
companies = fmp.search_name(query: 'Microsoft')
```

(Company Information)[https://site.financialmodelingprep.com/developer/docs#company-information]

```ruby
company_profile = fmp.profile(symbol: 'AAPL')
executive_compensations = fmp.executive_compensation(query: 'AAPL')
stock_grade = fmp.grade(query: 'AAPL')
```

(Earnings Calendar)[https://site.financialmodelingprep.com/developer/docs/earnings-calendar-api]

```ruby
earnings_announcements = fmp.earnings_calendar(from: '2024-05-01', to: '2024-05-10')
earnings_transcript = fmp.earning_call_transcript(symbol: 'AAPL', year: '2024', quarter: '1')
earnings_transcript = fmp.earning_call_transcript(symbol: 'AAPL') # can also be called without a year or quarter to see all upcoming
```

(SEC Filings)[https://site.financialmodelingprep.com/developer/docs#securities-and-exchange-commission-(s.e.c)]

```ruby
earnings_transcript = fmp.sec_filings(symbol: 'AAPL', type: '10-q', page: )
earnings_transcript = fmp.sec_filings(page: ) # all recent filings

```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/web2boomer/financial-modeling-prep.git](https://github.com/web2boomer/financial-modeling-prep.git). 