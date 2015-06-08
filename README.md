# Virtus::Relations

Adds relations to Virtus objects.

## Installation

In your Gemfile:

```ruby
gem 'virtus-relations'
```

In your source code:

```ruby
require 'virtus/relations'
```

## Usage examples
Given the following classes:
```ruby
require 'virtus/relations'

class Kid
  include Virtus.model

  attribute :name, String
end

class Mother
  include Virtus.model
  include Virtus.relations(as: :mom)

  attribute :name, String
  attribute :kid, Kid, relation: true, lazy: true, default: :load_kid

  def load_kid
    { name: 'Billy' }
  end
end
```

You can do the following:
```ruby
### Explicit assignment
alice = Mother.new(name: 'Alice')
alice.kid = { name: 'Danny' }
alice.kid.mom
# => <Mother:0x007fa43415fda8 @name="Alice", ...>

### Mass-assignment
emma = Mother.new(name: 'Emma', kid: { name: 'Johnny' })
emma.kid.mom
# => #<Mother:0x007fc40dbbdbf8 @name="Emma", ...>

### Lazy assignment
mia = Mother.new(name: 'Mia')
mia.kid.mom
# => #<Mother:0x007fa435d27130 @name="Mia", ...>

### Objects can still be created without a parent
orphan = Kid.new(name: 'Deirdre')
orphan.mom
# => NoMethodError: undefined method `mom' for #<Kid:0x007...
```

The `:as` option defaults to `:parent` when omitted

## Why relations?
Although regular attributes could be used to mimic this behavior, using relations can have two key benefits:

1. It does not create circular dependencies (known to cause issues with serializers)
2. It allows polymorphic relations (e.g. an Address can belong to either a User, or a Company)

## Contributing

1. Fork it
2. Create your feature branch
3. Comply with the [ruby style guide](https://github.com/bbatsov/ruby-style-guide)
4. Add tests for your new feature/bugfix. This is important so I don't break it in a future version unintentionally.
5. Submit a pull request
