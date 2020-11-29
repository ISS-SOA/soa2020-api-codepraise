# frozen_string_literal: true

folders = %w[requests services controllers]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
