require 'aws-sdk'
require 'json'

Aws.config.update(
  endpoint: 'https://dynamodb.us-east-2.amazonaws.com',
  region: 'us-east-2',
  credentials: Aws::Credentials.new(
    ENV['AWS_ACCESS_KEY_ID'],
    ENV['AWS_SECRET_ACCESS_KEY']
  )
)

# GET /api/all
def fetch_media_list(event:, context:)
  ddb = Aws::DynamoDB::Client.new
  ddb.scan({ table_name: 'Medias' })
rescue StandardError => e
  {
    statusCode: 500,
    message: "Error - unable to fetch media entries: #{e.message}"
  }
end

# POST /api/new
def create_media_entry(event:, context:)
  ddb = Aws::DynamoDB::Client.new
  ddb.put_item({
                 table_name: 'Medias',
                 item: {
                   id: UUID.new.generate,
                   title: title,
                   type: type,
                   status: status
                 }
               })
  {
    statusCode: 200
  }
rescue StandardError => e
  {
    statusCode: 500,
    message: "Error - unable to create media entry: #{e.message}"
  }
end

# POST /api/delete
def delete_media_entry(event:, context:)
  ddb = Aws::DynamoDB::Client.new
  ddb.delete_item({ table_name: 'Medias', key: { id: id } })
  {
    statusCode: 200
  }
rescue StandardError => e
  {
    statusCode: 500,
    text: "Error - could not delete media entry: #{e.message}"
  }
end

# TODO POST /api/update
def update_media_entry(event:, context:)
  db_client = Aws::DynamoDB::Client.new
  new_data = {
    title: {
      value: data[:title],
      action: 'PUT'
    },
    status: {
      value: data[:status],
      action: 'PUT'
    },
    type: {
      value: data[:type],
      action: 'PUT'
    }
  }
  db_client.update_item({ table_name: 'Medias', key: { id: id }, attribute_updates: new_data })
rescue StandardError => e
  {
    statusCode: 500,
    text: "Error updating media: #{e.message}"
  }
end