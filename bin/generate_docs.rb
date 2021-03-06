#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'lock_file'
require 'docs_generator'
require 'git_manager'

LockFile.acquiring('docs_generation.lock') do
  git_manager = GitManager.new(Dir.home)
  git_manager.update_master

  generator = DocsGenerator.new(Dir.home, git_manager)
  generator.generate
end
