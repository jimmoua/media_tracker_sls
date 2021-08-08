require 'aws-sdk'
require 'json'
require 'securerandom'

Aws.config.update(
  endpoint: ENV['sls_env'].eql?('dev') ? 'http://localhost:8000' : 'https://dynamodb.us-east-2.amazonaws.com',
  region: 'us-east-2'
)

class MediaTracker
  def self.fetch_media_list(event:, context:)
    list = ddb_client.scan({ table_name: 'Medias' })
    respond(200, list.items)
  rescue StandardError => e
    respond(500, { message: "Error - unable to fetch media list: #{e.message}" })
  end

  def self.create_media_entry(event:, context:)
    rq = JSON.parse(event['body'])
    mid = SecureRandom.uuid
    if rq['type'].nil? || rq['title'].nil? || rq['status'].nil? || rq['notes'].nil?
      return respond(400, { message: 'missing required request body' })
    end
    ddb_client.put_item(
      {
        table_name: 'Medias',
        item: {
          id: mid, type: rq['type'], status: rq['status'], title: rq['title'], notes: rq['notes'],
          last_updated: Time.new.iso8601.to_s
        }
      }
    )
    respond(200, {})
  rescue StandardError => e
    respond(500, { message: "Error - unable to create media entry: #{e.message}" })
  end

  def self.delete_media_entry(event:, context:)
    rq = JSON.parse(event['body'])
    mid = rq['id']
    return respond(404, {}) if ddb_client.get_item({ table_name: 'Medias', key: {id: rq['id']} }).item.nil?
    ddb_client.delete_item({ table_name: 'Medias', key: { id: mid } })
    respond(200, {})
  rescue StandardError => e
    respond(500, { message: "Error: could not delete media entry: #{e.message}" })
  end

  def self.update_media_entry(event:, context:)
    rq = JSON.parse(event['body'])
    resp = ddb_client.get_item(
      key: { id: rq['id'] },
      table_name: 'Medias'
    )
    return respond(404, { message: 'media not found' }) if resp[:item].nil?
    new_data = {}
    return respond(400, { message: 'messing media body' }) if rq['media'].nil?
    (rq['media'].map{ |k,v| { k => { value: v, action: 'PUT' } } }).each { |e| new_data.merge!(e) }
    if new_data['title'].nil? or new_data['status'].nil? or new_data['type'].nil? or new_data['notes'].nil?
      return respond(400, {})
    end
    new_data.merge!({ 'last_updated' => { 'value' => Time.now.iso8601.to_s, action: 'PUT' }})
    ddb_client.update_item({ table_name: 'Medias', key: { id: rq['id'] }, attribute_updates: new_data })
    respond(200, {})
  rescue StandardError => e
    respond(500, { message: "Error updating media: #{e.message}" })
  end

  private

  def self.ddb_client
    Aws::DynamoDB::Client.new
  end

  def self.respond(status_code, body)
    { statusCode: status_code, body: JSON.generate(body), headers: { 'Access-Control-Allow-Origin': '*' } }
  end
end