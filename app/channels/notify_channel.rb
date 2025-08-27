class NotifyChannel < ActionCable::Channel::Base
  extend Turbo::Streams::StreamName
  extend Turbo::Streams::Broadcasts
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    stream_name = verified_stream_name_from_params
    if stream_name.present? && subscription_allowed?
      stream_from stream_name
    else
      reject
    end
  end

  def unsubscribed
    reject
  end

  def subscription_allowed?
    user = User.find_by(id: params[:user_id])
    user&.id == current_user.id
  end
end
