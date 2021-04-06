require 'aws-sdk'
require 'json'
require 'uuid'

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
  rq = event
  ddb = Aws::DynamoDB::Client.new
  mid = UUID.new.generate
  ddb.put_item({
                 table_name: 'Medias',
                 item: {
                   id: mid,
                   title: rq['title'],
                   type: rq['type'],
                   status: rq['status']
                 }
               })
  {
    statusCode: 200,
    mediaID: mid,
  }
rescue StandardError => e
  {
    statusCode: 500,
    message: "Error - unable to create media entry: #{e.message}"
  }
end

# POST /api/delete
def delete_media_entry(event:, context:)
  rq = event
  ddb = Aws::DynamoDB::Client.new

  # Search for item, if not exists, return 404
  resp = ddb.get_item(
    key: {
      "id" => rq['id']
    },
    table_name: 'Medias'
  )
  if resp[:item].nil?
    return {
      statusCode: 404
    }
  end

  # Delete item
  ddb.delete_item({ table_name: 'Medias', key: { id: rq['id'] } })
  {
    statusCode: 200
  }
rescue StandardError => e
  {
    statusCode: 500,
    text: "Error - could not delete media entry: #{e.message}"
  }
end

# POST /api/update
def update_media_entry(event:, context:)
  rq = event
  ddb = Aws::DynamoDB::Client.new

  # Search for item, if not exists, return 404
  resp = ddb.get_item(
    key: {
      "id" => rq['id']
    },
    table_name: 'Medias'
  )
  if resp[:item].nil?
    return {
      statusCode: 404
    }
  end

  new_data = {
    title: {
      value: rq['title'],
      action: 'PUT'
    },
    status: {
      value: rq['status'],
      action: 'PUT'
    },
    type: {
      value: rq['type'],
      action: 'PUT'
    }
  }
  ddb.update_item({ table_name: 'Medias', key: { id: rq['id'] }, attribute_updates: new_data })
rescue StandardError => e
  {
    statusCode: 500,
    text: "Error updating media: #{e.message}"
  }
end
