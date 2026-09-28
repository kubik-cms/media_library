# frozen_string_literal: true

module KubikMediaLibrary
  class << self
    def gallery_untagged_requested?(params)
      params.to_h.with_indifferent_access[:media_untagged].to_s.in?(%w[1 true on])
    end
  end
end
