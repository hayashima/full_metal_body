# FullMetalBody

[![Test](https://github.com/hayashima/full_metal_body/actions/workflows/test.yml/badge.svg)](https://github.com/hayashima/full_metal_body/actions/workflows/test.yml)

FullMetalBody is a Rails Plugin for input validation in the before_action stage.

If you write a whitelist of parameters in a YAML file, only allowed keys and values will be passed through.

However, in other cases, for example, if it detects a string with control characters or a large number of strings aiming for overflow, it will immediately return `400 Bad Request`.

### Format of whitelist

```yaml
---
controller_name:
  action_name:
    parameter_name:
      type: (string|number|date|boolean)
      options:
        validator_option1: (value)
        validator_option2: (value)
    array_parameters:
      type: array
      properties:
        parameter_name:
          type: (string|number|date|boolean)
          options:
            validator_option1: (value)
            validator_option2: (value)
```

### Sample of whitelist

For example, suppose you have created a Scaffold for the `Article` model as shown below.

```bash
bin/rails g scaffold Article title:string content:text
```

The whitelist for it is as follows.

```yaml
---
articles:
  index:
    p:
      type: number
  show:
    id:
      type: number
  create:
    article:
      title:
        type: string
      content:
        type: string
        options:
          max_length: 4096
  edit:
    id:
      type: number
  update:
    id:
      type: number
    article:
      title:
        type: string
      content:
        type: string
        options:
          max_length: 4096
  destroy:
    id:
      type: number
```

## Table of contents

* [FullMetalBody](#fullmetalbody)
    * [Table of contents](#tableofcontents)
    * [Installation](#installation)
    * [Usage](#usage)
        * [Migration](#migration)
        * [Modify ApplicationController](#modifyapplicationcontroller)
        * [Creating a whitelist template](#creatingawhitelisttemplate)
        * [If you want to allow all parameters](#ifyouwanttoallowallparameters)
    * [Development](#development)
        * [Preparation](#preparation)
        * [Test](#test)
    * [Contributing](#contributing)
    * [License](#license)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "full_metal_body"
```

And then execute:

```bash
$ bundle
```

## Usage

### Migration

Create a migration file to store controllers, actions, and parameter keys that do not exist in the whitelist in the database.

```bash
bin/rails g full_metal_body:install
```

And then execute:

```bash
bin/rails db:migrate
```

The `blocked_actions` table and the `blocked_keys` table will be created in the database.

### Modify ApplicationController

Include `FullMetalBody::InputValidationAction` in ApplicationController.

```ruby
class ApplicationController < ActionController::Base
  include FullMetalBody::InputValidationAction
end
```

### Creating a whitelist template

You can write your own whitelist, but that's a lot of work.

Therefore, FullMetalBody creates a template whitelist in `tmp/whitelist/**/*.yml` by accessing each action in development mode, and then raises an exception.
At that time, the data will be registered in the blocked_actions table and the blocked_keys table.
Also, the contents will be output to the log.

For example, if you access `GET article_path(@article)`, `tmp/whitelist/articles.yml` will be created.

The contents will look like the following.

```yaml
---
articles:
  show:
    id:
      type: string
```

If you copy the contents to `config/whitelist/articles.yml` and then access it again, the exception will not occur.
By repeating this process for each action, we can create a whitelist.
By default, the whitelist is generated as `string`, so change the type to match the parameters (string|number|date|boolean).

Parameters will be merged into the template as needed for each action, so you don't have to delete them.
For example, if you access `DELETE article_path(@article)` after this, `tmp/whitelist/articles.yml` will look like this

```yaml
---
articles:
  destroy:
    id:
      type: string
  show:
    id:
      type: string
```

### If you want to allow all parameters

When using GraphQL, it is not possible to create a whitelist for the `variables` parameter, since it is defined on the client side.

In such a case, you need to allow everything under `variables`. If you want to allow them all, specify `_permit_all: true`.

```yaml
---
graphql:
  execute:
    operationName:
      type: string
    query:
      options:
        max_length: 1048576
      type: string
    variables:
      _permit_all: true
```

However, although all keys are allowed, to prevent attacks,
the type will be inferred from the value and the input value will be validated with the default rules for that type.

## Development

Please clone the repository and start development.

### Preparation

To develop, start PostgreSQL with docker-compose.

```bash
docker-compose up -d
```

And then execute:

```bash
bundle install
```

### Test

The test uses minitest.

```bash
bin/test
```

## Contributing

If you have any bug reports or pull requests, please let me know.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
