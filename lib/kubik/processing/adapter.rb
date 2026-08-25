# frozen_string_literal: true

module Kubik
  module Processing
    class Adapter
      def optimize(_record, _attacher)
        raise NotImplementedError
      end

      def create_derivative(_record, _attacher, _name, _spec)
        raise NotImplementedError
      end

      def available_modern_formats
        Kubik::Processing::FormatSupport.available_formats(
          KubikMediaLibrary.config.modern_formats
        )
      end
    end
  end
end
