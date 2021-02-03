# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"
require "zlib"

class AsJson
  def as_json(_options = nil)
    { a: 1 }
  end

  def to_json(_options = nil)
    '{"a":1}'
  end
end

describe Kiev::JSON do
  TEST_DATA = {
    Regexp: /test/,
    StringChinese: "二胡",
    StringSpecial: "\u2028\u2029><&",
    StringSpecial2: "\/",
    StringSpecial3: "\\\b\f\n\r\t",
    Time: Time.new(2012, 1, 5, 23, 58, 7.99996, 32_400),
    Date: Date.new(2012, 1, 5, 23),
    DateTime: DateTime.new(2012, 1, 5, 23, 58, 7.99996, 32_400),
    BigDecimal: BigDecimal("1") / 3,
    BigDecimalInfinity: BigDecimal("0.5") / 0,
    Float: 1.0 / 3,
    FloatInfinity: 0.5 / 0,
    Range: (1..10),
    Complex: Complex("0.3-0.5i"),
    Exception: Exception.new,
    OpenStruct: OpenStruct.new(country: "Australia", population: 20_000_000),
    Rational: Rational(0.3),
    AsJson: AsJson.new
  }

  before do
    @engine = Kiev::JSON.engine
  end

  after do
    Kiev::JSON.engine = @engine
  end

  subject { Kiev::JSON.generate(data) }
  let(:data) { TEST_DATA }

  it "accept all fancy stuff with Oj" do
    skip unless defined?(Oj)
    Kiev::JSON.engine = :oj
    expect(subject.frozen?).to be(false)
    # Obviously it's not Sidekiq itself, but env setup specific to Sidekiq
    if defined?(::Sidekiq)
      expect(subject).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\u2028\u2029><&\",\"StringSpecial2\":\"/\",\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\"," \
        "\"Time\":\"2012-01-05 23:58:07 +0900\",\"Date\":\"2012-01-05\",\"DateTime\":\"2012-01-05T23:58:07+00:00\"," \
        "\"BigDecimal\":\"0.333333333333333333e0\",\"BigDecimalInfinity\":\"Infinity\",\"Float\":0.3333333333333333," \
        "\"FloatInfinity\":null,\"Range\":\"1..10\",\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":\"#<OpenStruct country=\\\"Australia\\\", population=20000000>\"," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    elsif defined?(ActiveSupport::JSON)
      expect(subject).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\\u2028\\u2029\\u003e\\u003c\\u0026\",\"StringSpecial2\":\"/\"," \
        "\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\",\"Time\":\"2012-01-05T23:58:07.999+09:00\"," \
        "\"Date\":\"2012-01-05\",\"DateTime\":\"2012-01-05T23:58:07.999+00:00\"," \
        "\"BigDecimal\":\"0.333333333333333333\",\"BigDecimalInfinity\":null,\"Float\":0.3333333333333333," \
        "\"FloatInfinity\":null,\"Range\":\"1..10\",\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":{\"table\":{\"country\":\"Australia\",\"population\":20000000}}," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    else
      puts
      expect(subject).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\\u2028\\u2029\\u003e\\u003c\\u0026\",\"StringSpecial2\":\"/\"," \
        "\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\",\"Time\":\"2012-01-05 23:58:07 +0900\",\"Date\":\"2012-01-05\"," \
        "\"DateTime\":\"2012-01-05T23:58:07+00:00\",\"BigDecimal\":\"0.333333333333333333e0\"," \
        "\"BigDecimalInfinity\":null,\"Float\":0.3333333333333333,\"FloatInfinity\":null,\"Range\":\"1..10\"," \
        "\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":\"#\\u003cOpenStruct country=\\\"Australia\\\", population=20000000\\u003e\"," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    end
  end

  it "accept all fancy staff with ActiveSupport" do
    skip unless defined?(ActiveSupport::JSON)
    Kiev::JSON.engine = :activesupport
    expect(subject.frozen?).to be(false)
    # Obviously it's not Sidekiq itself, but env setup specific to Sidekiq
    if !defined?(::Sidekiq)
      expect(subject).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\\u2028\\u2029\\u003e\\u003c\\u0026\",\"StringSpecial2\":\"/\"," \
        "\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\",\"Time\":\"2012-01-05T23:58:07.999+09:00\"," \
        "\"Date\":\"2012-01-05\",\"DateTime\":\"2012-01-05T23:58:07.999+00:00\"," \
        "\"BigDecimal\":\"0.333333333333333333\",\"BigDecimalInfinity\":null,\"Float\":0.3333333333333333," \
        "\"FloatInfinity\":null,\"Range\":\"1..10\",\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":{\"table\":{\"country\":\"Australia\",\"population\":20000000}}," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    else
      expect(subject).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\\u2028\\u2029\\u003e\\u003c\\u0026\",\"StringSpecial2\":\"/\"," \
        "\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\",\"Time\":\"2012-01-05T23:58:07.999+09:00\"," \
        "\"Date\":\"2012-01-05\",\"DateTime\":\"2012-01-05T23:58:07.999+00:00\"," \
        "\"BigDecimal\":\"0.333333333333333333\",\"BigDecimalInfinity\":null,\"Float\":0.3333333333333333," \
        "\"FloatInfinity\":null,\"Range\":\"1..10\",\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":{\"table\":{\"country\":\"Australia\",\"population\":20000000}}," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    end
  end

  it "does accept some fancy staff without ActiveSupport and Oj" do
    skip unless defined?(::JSON)
    Kiev::JSON.engine = :json
    data = TEST_DATA.dup
    data.delete(:FloatInfinity)
    expect(subject.frozen?).to be(false)
    if defined?(ActiveSupport::JSON)
      expect(Kiev::JSON.generate(data)).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\u2028\u2029><&\",\"StringSpecial2\":\"/\",\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\"," \
        "\"Time\":\"2012-01-05 23:58:07 +0900\",\"Date\":\"2012-01-05\",\"DateTime\":\"2012-01-05T23:58:07+00:00\"," \
        "\"BigDecimal\":\"0.333333333333333333\",\"BigDecimalInfinity\":\"Infinity\",\"Float\":0.3333333333333333," \
        "\"Range\":\"1..10\",\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":\"#<OpenStruct country=\\\"Australia\\\", population=20000000>\"," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    else
      expect(Kiev::JSON.generate(data)).to eq(
        "{\"Regexp\":\"(?-mix:test)\",\"StringChinese\":\"二胡\"," \
        "\"StringSpecial\":\"\u2028\u2029><&\",\"StringSpecial2\":\"/\",\"StringSpecial3\":\"\\\\\\b\\f\\n\\r\\t\"," \
        "\"Time\":\"2012-01-05 23:58:07 +0900\",\"Date\":\"2012-01-05\",\"DateTime\":\"2012-01-05T23:58:07+00:00\"," \
        "\"BigDecimal\":\"0.333333333333333333e0\",\"BigDecimalInfinity\":\"Infinity\",\"Float\":0.3333333333333333," \
        "\"Range\":\"1..10\",\"Complex\":\"0.3-0.5i\",\"Exception\":\"Exception\"," \
        "\"OpenStruct\":\"#<OpenStruct country=\\\"Australia\\\", population=20000000>\"," \
        "\"Rational\":\"5404319552844595/18014398509481984\",\"AsJson\":{\"a\":1}}"
      )
    end
  end

  it "does not accept float infinity without ActiveSupport and Oj" do
    skip unless defined?(::JSON)
    Kiev::JSON.engine = :json
    expect(subject).to eq("{\"error_json\":\"failed to generate json\"}")
    expect(subject.frozen?).to be(false)
  end

  it "does not accept binary encoding" do
    # Obviously it's not Sidekiq itself, but env setup specific to Sidekiq
    skip if defined?(::Sidekiq)
    data = { body: Zlib::Deflate.deflate("some text") }
    expect(Kiev::JSON.generate(data)).to eq("{\"error_json\":\"failed to generate json\"}")
    expect(subject.frozen?).to be(false)
  end

  context :logstash do
    subject { Kiev::JSON.logstash(data) }

    context "binary encoding" do
      let(:data) { { body: Zlib::Deflate.deflate("some text") } }

      it "accepts binary encoding" do
        expect(subject).to eq("{\"body\":\"x?+??MU(I?(\\u0001\\u0000\\u0011?\\u0003?\"}\n")
      end
    end

    context "float infinity" do
      let(:data) { { FloatInfinity: 0.5 / 0, NegativeFloatInfinity: -0.5 / 0 } }

      it "accepts float infinity" do
        Kiev::JSON.engine = :json
        expect(subject).to eq("{\"FloatInfinity\":null,\"NegativeFloatInfinity\":null}\n")
      end
    end
  end
end
