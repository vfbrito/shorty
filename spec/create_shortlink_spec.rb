require_relative 'spec_helper'

RSpec.describe CreateShortlink, type: :model do
  subject { described_class.new(params) }

  context 'with shortcode' do
    let(:params) {
      {
        url: 'http://example.com',
        shortcode: 'example'
      }
    }

    let(:shortlink) { Shortlink.new(params[:shortcode]) }

    before do
      allow(Shortlink).to receive(:new).with(params[:shortcode]).and_return(shortlink)
      allow(shortlink).to receive(:create)
    end

    it 'should call create' do
      expect(shortlink).to receive(:create)
      subject.call
    end

    it 'should have shortlink shortcode equal to params shortcode' do
      subject.call
      expect(shortlink.shortcode).to eq(params[:shortcode])
    end

    it 'should have shortlink link equal to params url' do
      subject.call
      expect(shortlink.url).to eq(params[:url])
    end

    it 'should have shortlink redirect count equal do zero' do
      subject.call
      expect(shortlink.redirect_count).to eq(0)
    end

    it 'should have shortlink start date equal to now' do
      subject.call
      expect(shortlink.start_date).to eq(Time.now.iso8601)
    end

    it 'should have shortlink last seen date equal to nil' do
      subject.call
      expect(shortlink.last_seen_date).to eq(nil)
    end
  end

  context 'without shortcode' do
    let(:params) {
      {
        url: 'http://example.com'
      }
    }

    let(:shortlink) { Shortlink.new('') }

    before do
      allow(Shortlink).to receive(:new).and_return(shortlink)
      allow(shortlink).to receive(:create)
    end

    it 'should call create' do
      expect(shortlink).to receive(:create)
      subject.call
    end

    it 'should call random_shortcode' do
      expect(subject).to receive(:random_shortcode)
      subject.call
    end
  end
end
