# frozen_string_literal: true

folders = %w[responses representers]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
