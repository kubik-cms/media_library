# frozen_string_literal: true

module Kubik
  module_function

  def register_models!
    return if defined?(Kubik::MediaUpload)

    require "kubik/upload"
    require "kubik/media_upload"
  end
end
