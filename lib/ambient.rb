unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'project_helper'
require_relative 'dsl'

module Ambient
  extend self
  Ambient::ROOT = File.expand_path('.', File.dirname(__FILE__))

  @use_defaults = false
  @project_options = {}
  @shared_target_options = {}
  @target_options = {}
  @parents = {}
  def configure(&block)
    instance_eval &block
  end

  def project_helper
    @project_helper ||= ProjectHelper.new
  end

  def set_parent_target(target, child, parent)
    @parents[target] ||= {}
    @parents[target][child] = parent
  end

  def set_option(option, value, target: nil, scheme: nil, parent: nil)
    value = "YES" if value == true
    value = "NO" if value == false
    value = nil if value == :default

    if target
      if scheme
        @target_options[target] ||= {}
        @target_options[target][scheme] ||= {}
        @target_options[target][scheme][option] = value
      else
        # require 'pry'; binding.pry
        @shared_target_options[target] ||= {}
        @shared_target_options[target][option] = value
      end
    else
      @project_options[option] = value
    end
  end

  def setup_project
    project_helper.print_info
    reset_project_to_defaults
    reset_targets_to_defaults
    process_project_options
    process_shared_target_options
    process_target_options
  end

  def reset_project_to_defaults
    if @use_defaults
      puts "resetting project settings to xcode default settings"
      project_helper.reset_project_to_defaults
    end
  end

  def reset_targets_to_defaults
    if @use_defaults
      puts "resetting target settings to xcode default settings"
      project_helper.reset_targets_to_defaults
    end
  end

  def process_project_options
    puts "applying ambient project settings"
    project_helper.process_project_options(@project_options)
  end

  def process_shared_target_options
    puts "applying ambient shared target settings"
    project_helper.process_shared_target_options(@shared_target_options)
  end

  def process_target_options
    puts "applying ambient target settings"
    load_in_parent_target_values
    project_helper.process_target_options(@target_options)
  end

  def load_in_parent_target_values
    @parents.each do |target, parents|
      parents.each do |child, parent|
        if parent
          options = @target_options[target]
          child_options = options[child]
          parent_options = options[parent]
          child_options.merge!(parent_options) { |_, child, _| child }
        end
      end
    end
  end

  ambient = File.join(Dir.pwd, 'Ambientfile')
  raise "ambient not found" unless File.exists?(ambient)

  load ambient
end
