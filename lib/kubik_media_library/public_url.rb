# frozen_string_literal: true

module KubikMediaLibrary
  module PublicUrl
    module_function

    # Rails omits non-default ports for *.localhost Host headers (base_url becomes http://foo.localhost).
    # Use SERVER_PORT / ENV["PORT"] so admin PDF previews and copy-link URLs work on :3000.
    def request_origin(request)
      return if request.blank?

      scheme = request.scheme
      host = request.host
      port = port_for_request(request)

      if default_port?(scheme, port)
        "#{scheme}://#{host}"
      else
        "#{scheme}://#{host}:#{port}"
      end
    end

    def absolute(url, host: nil)
      return if url.blank?
      return url if url.match?(%r{\Ahttps?://}i)

      base = host.presence || default_host
      return url if base.blank?

      path = url.start_with?("/") ? url : "/#{url}"
      "#{base.to_s.chomp("/")}#{path}"
    end

    def default_host
      opts = ::Rails.application.routes.default_url_options
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

    def port_for_request(request)
      host_header = request.get_header("HTTP_HOST").to_s
      if host_header.include?(":") && !host_header.start_with?("[")
        return host_header.split(":", 2).last.to_i
      end

      server_port = request.get_header("SERVER_PORT").to_i
      return server_port if server_port.positive? && !default_port?(request.scheme, server_port)

      if defined?(::Rails) && (::Rails.env.development? || ::Rails.env.test?)
        env_port = ENV["PORT"].presence&.to_i
        return env_port if env_port&.positive?
      end

      request.port
    end
  end
end
