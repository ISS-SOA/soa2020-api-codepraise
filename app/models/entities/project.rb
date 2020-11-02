# frozen_string_literal: true

require_relative 'member'

module CodePraise
  module Entity
    # Domain entity for any coding projects
    class Project < Dry::Struct
      include Dry.Types

      MAX_SIZE_KB = 1000

      attribute :id,            Integer.optional
      attribute :origin_id,     Strict::Integer
      attribute :name,          Strict::String
      attribute :size,          Strict::Integer
      attribute :ssh_url,       Strict::String
      attribute :http_url,      Strict::String
      attribute :owner,         Member
      attribute :contributors,  Strict::Array.of(Member)

      def to_attr_hash
        to_hash.reject { |key, _| %i[id owner contributors].include? key }
      end

      def too_large?
        size > MAX_SIZE_KB
      end
    end
  end
end