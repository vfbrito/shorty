require_relative 'spec_helper'

RSpec.describe UpdateShortlink, type: :model do
  subject { described_class.new(shortlink) }

  let(:shortlink) { Shortlink.new('') }

  let(:params) {
    {
      url: 'http://example.com',
      shortcode: 'example'
    }
  }

  before do
    allow(shortlink).to receive(:increment)
    allow(shortlink).to receive(:update)
  end

  it 'should call increment' do
    expect(shortlink).to receive(:increment)
    subject.call
  end

  it 'should have shortlink last seen date equal to now' do
    subject.call
    expect(shortlink.last_seen_date).to eq(Time.now.iso8601)
  end

  it 'should call update' do
    expect(shortlink).to receive(:update)
    subject.call
  end
end
