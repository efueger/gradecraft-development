class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    user = User.last
    UserMailer.welcome_email user
  end
  
  def activation_needed_email
    user = User.last
    # arbitrary value for testing purposes
    user.activation_token = 102
    UserMailer.activation_needed_email user
  end
  
  def reset_password_email
    user = User.last
    # arbitrary value for testing purposes
    user.reset_password_token = 101
    UserMailer.reset_password_email user
  end
end