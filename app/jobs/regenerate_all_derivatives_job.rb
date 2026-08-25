# frozen_string_literal: true

class RegenerateAllDerivativesJob < ApplicationJob
  def perform
    Kubik::MediaUpload.where.not(image_data: nil).find_each do |record|
      record.regenerate_derivatives!
    end
  end
end
