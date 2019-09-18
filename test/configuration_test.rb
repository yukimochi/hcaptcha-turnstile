require_relative 'helper'

describe Hcaptcha::Configuration do
  describe "#api_server_url" do
    it "serves the default" do
      Hcaptcha.configuration.api_server_url.must_equal "https://hcaptcha.com/1/api.js"
    end

    describe "when api_server_url is overwritten" do
      it "serves the overwritten url" do
        proxied_api_server_url = 'https://127.0.0.1:8080/hcaptcha/api.js'
        Hcaptcha.with_configuration(api_server_url: proxied_api_server_url) do
          Hcaptcha.configuration.api_server_url.must_equal proxied_api_server_url
        end
      end
    end
  end

  describe "#verify_url" do
    it "serves the default" do
      Hcaptcha.configuration.verify_url.must_equal "https://hcaptcha.com/siteverify"
    end

    describe "when api_server_url is overwritten" do
      it "serves the overwritten url" do
        proxied_verify_url = 'https://127.0.0.1:8080/hcaptcha/siteverify'
        Hcaptcha.with_configuration(verify_url: proxied_verify_url) do
          Hcaptcha.configuration.verify_url.must_equal proxied_verify_url
        end
      end
    end
  end

  it "can overwrite configuration in a block" do
    outside = '0000000000000000000000000000000000000000'
    Hcaptcha.configuration.site_key.must_equal outside

    Hcaptcha.with_configuration(site_key: '12345') do
      Hcaptcha.configuration.site_key.must_equal '12345'
    end

    Hcaptcha.configuration.site_key.must_equal outside
  end

  it "cleans up block configuration after block raises an exception" do
    before = Hcaptcha.configuration.site_key.dup

    assert_raises NoMemoryError do
      Hcaptcha.with_configuration(site_key: '12345') do
        Hcaptcha.configuration.site_key.must_equal '12345'
        raise NoMemoryError, "an exception"
      end
    end

    Hcaptcha.configuration.site_key.must_equal before
  end
end
