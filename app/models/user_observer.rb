class UserObserver < ActiveRecord::Observer
  def after_create(user)
    # No activation required, so don't send an email
    #UserNotifier.deliver_signup_notification(user)
  end

  def after_save(user)
  end
end