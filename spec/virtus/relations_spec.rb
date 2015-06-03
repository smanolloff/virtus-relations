require 'spec_helper'
require 'active_support/core_ext/object/instance_variables'

describe Virtus::Relations do
  # The child
  class C
    include Virtus.model
  end

  # The parent, referenced by Child#parent
  class P
    include Virtus.model
    include Virtus.relations

    attribute :c_1, C, relation: true
    attribute :c_2, C, relation: true, lazy: true, default: :load_c_2
    attribute :c_3, C, relation: true, lazy: true, default: proc { {} }
    attribute :c_4, Array[C], relation: true
    attribute :c_5, Array[C], relation: true,  lazy: true, default: :load_c_5
    attribute :c_6, Array[C], relation: true,  lazy: true, default: proc { [{}] }

    def load_c_2
      {}
    end

    def load_c_5
      [{}]
    end
  end

  # Another parent, but referenced by Child#father
  class F
    include Virtus.model
    include Virtus.relations(as: :father)

    attribute :c, C, relation: true
  end

  it 'allow to specify a relation name' do
    f = F.new
    f.c = {}

    expect(f.c.father).to be(f)
  end

  describe 'Object#parent' do
    context 'when initialized via a related attribute' do
      context 'of non-array type' do
        context 'and is mass-assigned' do
          let(:p) { P.new(c_1: {}) }

          it 'returns the attribute owner' do
            expect(p.c_1.parent).to be(p)
          end

          it 'does not store its return value in an instance variable' do
            expect(p.c_1.instance_values.values).not_to include(p)
          end
        end

        context 'and is strictly initialized' do
          it 'returns the attribute owner' do
            p = P.new
            p.c_1 = {}
            expect(p.c_1.parent).to be(p)
          end
        end

        context 'and is lazily initialized via a method' do
          it 'returns the attribute owner' do
            p = P.new
            expect(p.c_2.parent).to be(p)
          end
        end

        context 'and is lazily initialized via a proc' do
          it 'returns the attribute owner' do
            p = P.new
            p.c_3
            expect(p.c_3.parent).to be(p)
          end
        end
      end

      context 'of an array type' do
        context 'and is mass-assigned' do
          it 'returns the attribute owner' do
            p = P.new(c_4: [{}])
            expect(p.c_4.first.parent).to be(p)
          end
        end

        context 'and is strictly initialized' do
          it 'returns the attribute owner' do
            p = P.new
            p.c_4 = [{}]
            expect(p.c_4.first.parent).to be(p)
          end
        end

        context 'and is lazily initialized via a method' do
          it 'returns the attribute owner' do
            p = P.new
            expect(p.c_5.first.parent).to be(p)
          end
        end

        context 'and is lazily initialized via a proc' do
          it 'returns the attribute owner' do
            p = P.new
            expect(p.c_6.first.parent).to be(p)
          end
        end
      end
    end
  end

  describe ''

end
