# frozen_string_literal: true

module KubikMediaLibrary
  module PublicUrl
    module_function

    def absolute(url, host: nil)
      return if url.blank?
      return url if url.match?(%r{\Ahttps?://}i)

      base = host.presence || default_host
      return url if base.blank?

      path = url.start_with?("/") ? url : "/#{url}"
      "#{base.to_s.chomp("/")}#{path}"
    end

    def default_host
      opts = Rails.application.routes.default_url_options
      host = opts[:host]
      return if host.blank?

      protocol = (opts[:protocol] || "http").to_s
      port = opts[:port]
      origin = "#{protocol}://#{host}"
      return origin if port.blank?
      return origin if default_port?(protocol, port)

      "#{origin}:#{port}"
    end

    def default_port?(protocol, port)
      (protocol == "http" && port.to_i == 80) ||
        (protocol == "https" && port.to_i == 443)
    end
  end
end
