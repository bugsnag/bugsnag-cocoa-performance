# frozen_string_literal: true

require 'base64'

module ReflectiveServletResponseOverrides
  def do_GET(request, response)
    super
    apply_reflect_overrides(request, response)
  end

  def do_POST(request, response)
    super
    apply_reflect_overrides(request, response)
  end

  private

  def apply_reflect_overrides(request, response)
    query = request.query || {}
    status_override = request['Bugsnag-Reflect-Status'] || query['status']
    body_b64_override = request['Bugsnag-Reflect-Body-Base64'] || query['body_b64']
    body_override = request['Bugsnag-Reflect-Body'] || query['body']
    delay_override = request['Bugsnag-Reflect-Delay-Ms'] || query['delay_ms']

    sleep delay_override.to_i / 1000.0 if delay_override && !delay_override.empty?

    if body_b64_override && !body_b64_override.empty?
      begin
        body_override = Base64.decode64(body_b64_override)
      rescue StandardError
        # Fall back to raw body override if base64 decode fails.
      end
    end

    response.status = status_override.to_i if status_override && !status_override.empty?
    response.body = body_override if body_override && !body_override.empty?
  end
end

Maze::Servlets::ReflectiveServlet.prepend(ReflectiveServletResponseOverrides)
