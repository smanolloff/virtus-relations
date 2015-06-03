require 'virtus'
require 'virtus/relations/version'

module Virtus
  def self.relations(params = {})
    rel_name = params.fetch(:as, :parent)
    fail TypeError, 'Symbol expected' unless rel_name.is_a?(Symbol)

    mod = Module.new
    mod.instance_variable_set(:@rel_name, rel_name)

    mod.module_eval do
      def self.class_methods
        Module.new do
          # During instantiation, .relation_attributes is called
          # If class was instantiated before, just return the list of related attributes
          #
          # If instantiated for the first time, then monkey-patch some instance
          # methods to allow relation attributes to work with accessor methods.
          #
          #
          # patch Model#attribute=
          #
          #   1. create {list}
          #   2. for each {attribute} in {list}
          #   2.1. patch the accessor method
          #   2.2. patch the lazy initializer method (if any)
          #
          def relation_attributes
            @relation_attributes ||= attribute_set.select do |attribute|
              next unless attribute.options[:relation] == true

              patch_accessor_method(attribute)
              patch_lazy_initializer(attribute)
              true
            end
          end

          #
          # When the original method returns something, we need to
          # actually set ourselves as its parent
          # If that something is a collection, do it for each element
          #
          def relate(object, method_return)
            if object.kind_of?(Array)
              object.each { |o| relate(o, method_return) }
            else
              object.define_singleton_method(relation_name) { method_return }
              object
            end
          end


          protected
          #   1. rename method "{attribute}=" to "{attribute}_not_related="
          #   2. define method "{attribute}=", which:
          #     2.1. calls "{attribute}_not_related=", takes the {return_object}
          #     2.2. defines {return_object}.parent which returns self
          #     2.3. returns {return_object}
          #   3. return the list
          def patch_accessor_method(attribute)
            if [Numeric, Symbol].any? { |c| attribute.primitive.ancestors.include?(c) }
              fail "Relations don't work with Numeric and Symbol types"
            end

            old_method = "#{attribute.name}_not_related="
            new_method = "#{attribute.name}="

            # Suffix the original method with '_not_related'
            define_method(old_method, instance_method(new_method))
            define_method(new_method) do |value|
              return_value = send(old_method, value)
              self.class.relate(return_value, self)
            end

            private old_method
            visibility = attribute.options[:writer]
            send(visibility, new_method)
          end

          # (see above for the explanation of step 2.)
          #   Wrap the original method/proc into a new one, which:
          #   1. calls the original one, takes the {return_object}
          #   2. coerces {return_object}
          #   3. defines {return_object}.parent which returns self
          #   4. returns {return_object}
          #
          def patch_lazy_initializer(attribute)
            return unless attribute.lazy?

            case attribute.default_value.value
            when Proc
              old_proc = attribute.default_value.value
              new_proc = proc do |object, *_|
                return_value = attribute.coerce(old_proc.call(*[object, *_]))
                object.class.relate(return_value, object)
              end

              attribute.default_value.instance_variable_set(:@value, new_proc)
            else
              old_method = "#{attribute.default_value.value}_not_related"
              new_method = attribute.default_value.value
              visibility = if private_method_defined?(new_method)
                             :private
                           elsif protected_method_defined?(new_method)
                             :protected
                           else
                             :public
                           end

              define_method(old_method, instance_method(new_method))
              define_method(new_method) do
                return_value = attribute.coerce(send(old_method))
                self.class.relate(return_value, self)
                return_value
              end

              private old_method
              send(visibility, new_method)
            end
          end
        end # Module.new
      end # def

      def self.instance_methods
        Module.new do
          #
          # Enhance the initialize process to allow
          # related attributes to work with mass-assignment
          #
          def initialize(mass_assignment_attributes = {})
            super

            self.class.relation_attributes.each do |ra|
              # set self as the child's parent only if child was mass-
              # assigned during self.initialize (e.g. hash has child's key)
              # This prevents children from doing this against the parents
              # when they also have relation: true on their attributes
              # (since their initializers will not receive the parent as
              #  a part of the mass-assignment)

              if mass_assignment_attributes.key?(ra.name)
                self.class.relate(ra.get(self), self)
              end
            end
          end

          alias_method :dup_not_related, :dup

          # Add #parent to duped objects, when available
          def dup
            rel = self.class.relation_name
            if respond_to?(rel)
              self.class.relate(dup_not_related, rel)
            else
              dup_not_related
            end
          end

        end # Module.new
      end # def

      def self.included(base)
        required = [
          Virtus::InstanceMethods::MassAssignment,
          Virtus::InstanceMethods::Constructor
        ]

        unless required.all? { |mod| base.included_modules.include?(mod) }
          fail 'Virtus.model must be included prior to Virtus.relations'
        end

        # Using a local variable in the parent scope
        # with the same name as the singleton method
        # prevents recursion
        relation_name = @rel_name
        base.define_singleton_method(:relation_name) { relation_name }

        base.send(:include, instance_methods)
        base.extend(class_methods)
      end

      mod
    end
  end
end
