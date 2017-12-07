require_relative 'spec_helper'

RSpec.describe 'App' do
  describe 'POST /shorten' do
    subject { -> { post '/shorten', params } }

    context 'with valid params and shortcode requested' do
      let(:params) {
        {
          shortcode: 'example',
          url: 'http://example.com'
        }
      }

      let(:expected_response) {
        {
          shortcode: params[:shortcode]
        }
      }

      it 'should respond with status 201 created' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq(expected_response.to_json)
      end
    end

    context 'with valid params without shortcode' do
      let(:params) {
        {
          url: 'http://example.com'
        }
      }

      let(:shortcode) { Faker::Base.regexify(/[0-9a-zA-Z_]{6}/) }

      let(:expected_response) {
        {
          shortcode: shortcode
        }
      }

      before do
        allow_any_instance_of(Shortlink).to receive(:shortcode).and_return(expected_response[:shortcode])
      end

      it 'should respond with status 201 created' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq(expected_response.to_json)
      end
    end

    context 'with url not present' do
      let(:params) {
        {
          shortcode: 'example'
        }
      }

      let(:expected_response) {
        'url is not present'
      }

      it 'should respond with status 400 bad request' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq(expected_response)
      end
    end

    context 'with url empty' do
      let(:params) {
        {
          shortcode: 'example',
          url: ''
        }
      }

      let(:expected_response) {
        'url is not present'
      }

      it 'should respond with status 400 bad request' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq(expected_response)
      end
    end

    context 'with shortcode already in use' do
      let(:params) {
        {
          shortcode: 'example',
          url: 'http://example.com'
        }
      }

      let(:expected_response) {
        'The the desired shortcode is already in use'
      }

      it 'should respond with status 409 conflict' do
        subject.call
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(409)
        expect(last_response.body).to eq(expected_response)
      end
    end

    context 'with invalid shortcode' do
      let(:params) {
        {
          shortcode: 'ex',
          url: 'http://example.com'
        }
      }

      let(:expected_response) {
        'The shortcode fails to meet the following regexp: ^[0-9a-zA-Z_]{4,}$'
      }

      it 'should respond with status 422 unprocessable entity' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(422)
        expect(last_response.body).to eq(expected_response)
      end
    end
  end

  describe 'GET /:shortcode' do
    subject { -> { get "/#{params[:shortcode]}" } }

    context 'with valid shortcode' do
      let(:params) {
        {
          shortcode: 'example'
        }
      }

      let(:shortlink) { OpenStruct.new }

      let(:url) { 'http://example.com' }

      before do
        allow(Shortlink).to receive(:find).with(params[:shortcode]).and_return(shortlink)
        allow(shortlink).to receive(:url).and_return(url)
      end

      it 'should respond with status 303 see other' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(303)
        expect(last_response.location).to eq(url)
      end
    end

    context 'with invalid shortcode' do
      let(:params) {
        {
          shortcode: 'example'
        }
      }

      let(:expected_response) {
        'The shortcode cannot be found in the system'
      }

      it 'should respond with status 404 not found' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq(expected_response)
      end
    end
  end

  describe 'GET /:shortcode/stats' do
    subject { -> { get "/#{params[:shortcode]}/stats" } }

    context 'with valid shortcode' do
      let(:params) {
        {
          shortcode: 'example'
        }
      }

      let(:shortlink) { OpenStruct.new }

      let(:expected_response) {
        {
          start_date: Time.now.iso8601,
          last_seen_date: Time.now.iso8601,
          redirect_count: 1
        }
      }

      before do
        allow(Shortlink).to receive(:find).with(params[:shortcode]).and_return(shortlink)
        allow(shortlink).to receive(:start_date).and_return(expected_response[:start_date])
        allow(shortlink).to receive(:last_seen_date).and_return(expected_response[:last_seen_date])
        allow(shortlink).to receive(:redirect_count).and_return(expected_response[:redirect_count])
      end

      it 'should respond with status 200 OK' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(expected_response.to_json)
      end
    end

    context 'with invalid shortcode' do
      let(:params) {
        {
          shortcode: 'example'
        }
      }

      let(:expected_response) {
        'The shortcode cannot be found in the system'
      }

      it 'should respond with status 404 not found' do
        subject.call
        expect(last_response.content_type).to eq('application/json')
        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq(expected_response)
      end
    end
  end
end