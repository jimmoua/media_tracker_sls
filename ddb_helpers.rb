require 'aws-sdk'
require 'json'
require 'securerandom'

Aws.config.update(
  # endpoint: 'https://dynamodb.us-east-2.amazonaws.com',
  endpoint: 'http://localhost:8000',
  region: 'us-east-2'
)

def get_headers
  {
    'Access-Control-Allow-Origin': '*'
  }
end

# GET /api/all
def fetch_media_list(event:, context:)
  ddb = Aws::DynamoDB::Client.new
  l = ddb.scan({ table_name: 'Medias' })
  {
    statusCode: 200,
    body: JSON.generate(l.items),
    headers: get_headers
  }
rescue StandardError => e
  {
    statusCode: 500,
    body: JSON.generate(
      {
        message: "Error - unable to fetch media entries: #{e.message}"
      }
    ),
    headers: get_headers
  }
end

# POST /api/new
def create_media_entry(event:, context:)
  rq = JSON.parse(event['body'])
  ddb = Aws::DynamoDB::Client.new
  mid = SecureRandom.uuid
  if rq['type'].nil? || rq['title'].nil? || rq['status'].nil?
    return {
      statusCode: 400,
      body: JSON.generate(
        {
          text: 'Please provide type, title, and status'
        }
      ),
      headers: get_headers
    }
  end
  ddb.put_item(
    {
      table_name: 'Medias',
      item: {
        id: mid,
        type: rq['type'],
        status: rq['status'],
        title: rq['title'],
        last_updated: Time.new.iso8601.to_s
      }
    }
  )
  {
    statusCode: 200,
    headers: get_headers
  }
rescue StandardError => e
  {
    statusCode: 500,
    body: JSON.generate(
      {
        message: "Error - unable to create media entry: #{e.message}"
      }
    ),
    headers: get_headers
  }
end

# POST /api/delete
def delete_media_entry(event:, context:)
  rq = JSON.parse(event['body'])
  mid = rq['id']
  ddb = Aws::DynamoDB::Client.new
  ddb.delete_item({ table_name: 'Medias', key: { id: mid } })
  {
    statusCode: 200,
    headers: get_headers
  }
rescue StandardError => e
  {
    statusCode: 500,
    body: JSON.generate(
      {
        text: "Error - could not delete media entry: #{e.message}"
      }
    ),
    headers: get_headers
  }
end

# POST /api/update
def update_media_entry(event:, context:)
  rq = JSON.parse(event['body'])
  ddb = Aws::DynamoDB::Client.new
  # Search for item, if not exists, return 404
  resp = ddb.get_item(
    key: {
      id: rq['id']
    },
    table_name: 'Medias'
  )
  if resp[:item].nil?
    return {
      statusCode: 404,
      headers: get_headers
    }
  end

  # check to see if they actually modified anything
  item = resp[:item]
  if item['title'].eql?(rq['title']) && item['type'].eql?(rq['type']) && item['status'].eql?(rq['status'])
    return {
      statusCode: 204,
      body: JSON.generate(
        {
          text: "Nothing to update."
        }
      ),
      headers: get_headers
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
    },
    last_updated: {
      value: Time.now.iso8601.to_s,
      action: 'PUT'
    }
  }
  ddb.update_item({ table_name: 'Medias', key: { id: rq['id'] }, attribute_updates: new_data })
  {
    statusCode: 200,
    headers: get_headers
  }
rescue StandardError => e
  {
    statusCode: 500,
    body: JSON.generate(
      {
        text: "Error updating media: #{e.message}"
      }
    ),
    headers: get_headers
  }
end
