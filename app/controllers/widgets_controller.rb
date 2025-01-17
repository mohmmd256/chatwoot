class WidgetsController < ActionController::Base
  before_action :set_global_config
  before_action :set_web_widget
  before_action :set_token
  before_action :set_contact
  before_action :build_contact
  after_action :allow_iframe_requests

  def index; end

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'INSTALLATION_NAME', 'WIDGET_BRAND_URL')
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_token
    @token = permitted_params[:cw_conversation]
    @auth_token_params = if @token.present?
                           ::Widget::TokenService.new(token: @token).decode_token
                         else
                           {}
                         end
  end

  def set_contact
    return if @auth_token_params[:source_id].nil?

    contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: @auth_token_params[:source_id]
    )

    @contact = contact_inbox ? contact_inbox.contact : nil
  end

  def build_contact
    return if @contact.present?

    contact_inbox = @web_widget.create_contact_inbox
    @contact = contact_inbox.contact

    payload = { source_id: contact_inbox.source_id, inbox_id: @web_widget.inbox.id }
    @token = ::Widget::TokenService.new(payload: payload).generate_token
  end

  def permitted_params
    params.permit(:website_token, :cw_conversation)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end
