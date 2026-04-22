Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_payload do |controller|
    {
      user_id: controller.try(:current_user)&.id,
      ip: controller.request.remote_ip
    }
  end

  config.lograge.custom_options = lambda do |event|
    {
      params: event.payload[:params].except("controller", "action", "format", "password")
    }
  end
end
