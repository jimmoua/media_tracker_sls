# Media Tracker Serverless
A personal API that I use to keep track of my favorite shows. Deployed onto AWS Lambda+Cognito.

The frontend repository can be found here: https://www.github.com/jimmoua/media-tracker-frontend

## Ruby Version
Since AWS only support Ruby 2.7 so far for Lambda, this is the currently Ruby version required for development.

## Setup
Install the needed Gems for development
```
$ bundle install
```

## Tests
Unit tests are written with `RSpec` framework. Tests are found in the `spec` folder and ends with the `*_spec.rb` pattern.

Run tests with the command
```
$ rspec
```

Coverage will be generated with `Simplecov`. Check `coverage/index.html` to see coverage of code when running the `rspec` command.
