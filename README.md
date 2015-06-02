# Virtus::Relations

Add relation-like support to Virtus models.

## Installation

In your Gemfile:

```ruby
gem 'virtus-relations'
```

In your source code:

```ruby
require 'virtus/relations'
```

## Usage

Example:
```ruby
require 'virtus/relations'

class Address
  include Virtus.model
  include Virtus.relations

  attribute :city, String
end

class User
  include Virtus.model
  include Virtus.relations

  attribute :name, String
  attribute :address, Address, relation: true, lazy: true, default: :load_address

  def load_address
    { city: 'Paris' }
  end
end

## Mass-assignment
u = User.new(name: 'Bob', address: { city: 'Vegas' })
u.address.parent.eql?(u)
# => true

## Explicit assignment
u2 = User.new(name: 'Dan')
u2.address = { city: 'LA' }
u2.address.parent.eql?(u2) # => true

## Lazy assignment
u3 = User.new(name: 'Luke')
u3.address.parent.eql?(u3) # => true

## A child can still be created without a parent
a = Address.new
a.parent
# => NoMethodError: undefined method `parent' for #<Address:0x007...
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/virtus-relations/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
