# frozen_string_literal: true

module Kubik
  module DerivativesCompletion
    module_function

    def finalize_if_complete!(record)
      record.reload
      record.finalize! if record.derivatives_complete? && record.may_finalize?
    end
  end
end
