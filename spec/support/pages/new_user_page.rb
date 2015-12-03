require_relative "user_page"

class NewUserPage < UserPage
  include Capybara::DSL

  def submit(fields={})
    fill_out_form fields
    click_button "Create User"
  end
end
