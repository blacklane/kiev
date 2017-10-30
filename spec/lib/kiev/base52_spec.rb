# frozen_string_literal: true

require "spec_helper"

describe Kiev::Base52 do
  describe "encode" do
    subject { (0..51).map(&Kiev::Base52.method(:encode)) }

    it "can encode 52 numbes in unique way" do
      expect(subject.uniq.length).to eq(52)
    end

    it "can encode 52 numbes with one char" do
      expect(subject.map(&:length).reduce(:+)).to eq(52)
    end

    it "produces 52 lexicographically sortable values" do
      (0..50).each do |x|
        expect(Kiev::Base52.encode(x) < Kiev::Base52.encode(x + 1)).to eq(true)
      end
    end
  end
end
