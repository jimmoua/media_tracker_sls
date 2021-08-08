require 'simplecov'
SimpleCov.start

require 'spec_helper'
require_relative '../handler.rb'
require 'aws-sdk'

RSpec.describe 'MediaTracker API' do
  # WARNING: do not change the below to live AWS endpoints
  before(:all) do
    Aws.config.update(endpoint: 'http://localhost:8000')
  end

  let :ddb do
    Aws::DynamoDB::Client.new
  end

  let :unstub do
    allow(Aws::DynamoDB::Client).to receive(:new).and_call_original # clear the stub if any
  end

  let :clear_db do
    unstub
    id_list = ddb.scan({ table_name: 'Medias' }).items.map { |x| x['id'] }
    id_list.each do |id|
      ddb.delete_item({ table_name: 'Medias', key: { id: id } })
    end
  end

  describe 'GET /api/medias' do
    describe 'a good fetch' do
      it 'fetches the list' do
        response = MediaTracker.fetch_media_list(event: {}, context: {})
        expect(response[:statusCode]).to eql(200)
      end
    end

    describe 'failure to fetch' do
      it 'returns 500' do
        allow(Aws::DynamoDB::Client).to receive(:new).and_raise(StandardError)
        response = MediaTracker.fetch_media_list(event: {}, context: {})
        expect(response[:statusCode]).to eql(500)
      end
    end
  end

  describe 'POST /api/medias' do
    after(:each) do
      clear_db
    end

    describe 'providing all parameters' do
      it 'saves the media list' do
        ev = {
          "body" => JSON.generate(
            'title'=>'One Piece',
            'type'=>'Comic',
            'status'=>'Chapter 100',
            'notes'=>''
          )
        }
        response = MediaTracker.create_media_entry(event: ev, context: {})
        expect(response[:statusCode]).to eql(200)
        item = ddb.scan({ table_name: 'Medias' }).items.first
        expect(item['title']).to eql('One Piece')
      end
    end

    describe 'with missing parameters' do
      ev = {
        'body' => JSON.generate(
          'title' => 'One Piece'
        )
      }
      it 'should return a 400 response status' do
        response = MediaTracker.create_media_entry(event: ev, context: {})
        expect(response[:statusCode]).to eql(400)
      end
    end

    describe 'when db client is unable to save or is not correct' do
      it 'returns 500' do
        allow(Aws::DynamoDB::Client).to receive(:new).and_raise(StandardError)
        response = MediaTracker.create_media_entry(event: {}, context: {})
        expect(response[:statusCode]).to eql(500)
      end
    end
  end

  describe 'DELETE /api/medias' do
    describe 'an id is given' do
      it 'should delete the media with the id 123' do
        ev = {
          'body' => JSON.generate(
            'id' => '123'
          )
        }
        ddb.put_item({ table_name: 'Medias', item: { id: '123' } })
        expect(ddb.get_item({ table_name: 'Medias', key: { id: '123' } }).item).to_not be_nil
        response = MediaTracker.delete_media_entry(event: ev, context: {})
        expect(response[:statusCode]).to eql(200)
        expect(ddb.get_item({ table_name: 'Medias', key: { id: '123' } }).item).to be_nil
      end

      describe 'the id is not found' do
        it 'returns 404' do
          response = MediaTracker.delete_media_entry(event: {'body' => JSON.generate('id' => 'some_id')}, context: {})
          expect(response[:statusCode]).to eql(404)
        end
      end
    end

    describe 'ddb client failure' do
      it 'returns 500' do
        allow(Aws::DynamoDB::Client).to receive(:new).and_raise(StandardError)
        ev = {
          'body' => JSON.generate(
            'id' => 'does not matter'
          )
        }
        response = MediaTracker.delete_media_entry(event: ev, context: {})
        expect(response[:statusCode]).to eql(500)
      end
    end
  end

  describe 'PUT /api/medias' do
    after(:each) do
      clear_db
    end

    describe 'when the id is not found' do
      it 'returns 404' do
        ev = {
          'body' => JSON.generate(
            'id' => 'some_id'
          )
        }
        response = MediaTracker.update_media_entry(event: ev, context: {})
        expect(response[:statusCode]).to eql(404)
      end
    end

    describe 'a valid id is provided' do
      let :ev do
        {
          'body' => JSON.generate(
            'id' => '123',
            'media' => {
              'title' => 'One Piece',
              'type' => 'Show',
              'status' => 'Episode 1',
              'notes' => ''
            }
          )
        }
      end

      it 'updates the media' do

        ddb.put_item({ table_name: 'Medias', item: { id: '123' }})
        expect(ddb.get_item({ table_name: 'Medias', key: { id: '123' } }).item).to_not be_nil
        response = MediaTracker.update_media_entry(event: ev, context: {})
        expect(response[:statusCode]).to eql(200)
        item = ddb.get_item({ table_name: 'Medias', key: { id: '123' } }).item
        expect(item['title']).to eql('One Piece')
        expect(item['type']).to eql('Show')
        expect(item['status']).to eql('Episode 1')
        expect(item['notes']).to eql('')
        expect(item['last_updated']).to_not be_nil
      end

      describe 'missing media body' do
        it 'returns 400' do
          ddb.put_item({ table_name: 'Medias', item: { id: '123' } })
          expect(ddb.get_item({ table_name: 'Medias', key: { id: '123' } }).item).to_not be_nil
          response = MediaTracker.update_media_entry(event: {'body' => JSON.generate('id' => '123', 'media' => {})}, context: {})
          expect(response[:statusCode]).to eql(400)
        end
      end

      describe 'ddb client failure' do
        it 'returns 500' do
          allow(Aws::DynamoDB::Client).to receive(:new).and_raise(StandardError)
          response = MediaTracker.update_media_entry(event: {}, context:{})
          expect(response[:statusCode]).to eql(500)
        end
      end
    end
  end
end