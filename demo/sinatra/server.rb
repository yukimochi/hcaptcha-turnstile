require 'bundler/setup'
require 'sinatra'
require 'hcaptcha'

set :bind, 'test.mydomain.com'
set :port, 3000

Hcaptcha.configure do |config|
  config.site_key  = '1161d0be-1130-4af5-8999-b6fa8894e2a8'
  config.secret_key = '0x2c87B9A9B41a6112FEC89dd16C138DDEe62D9472'
end

include Hcaptcha::Adapters::ControllerMethods
include Hcaptcha::Adapters::ViewMethods

get '/' do
  <<-HTML
    <form action="/verify">
      #{hcaptcha_tags}
      <input type="submit"/>
    </form>
  HTML
end

get '/verify' do
  if verify_hcaptcha
    'YES!'
  else
    'NO!'
  end
end
