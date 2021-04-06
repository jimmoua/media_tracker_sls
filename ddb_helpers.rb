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

def fetch_media_list(event:, context:)
  ddb = Aws::DynamoDB::Client.new
  ddb.scan({ table_name: 'Medias' })
rescue StandardError => e
  {
    statusCode: 500,
    message: "Error: #{e.message}"
  }
end
