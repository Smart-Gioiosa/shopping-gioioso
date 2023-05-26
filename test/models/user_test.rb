require "test_helper"

class UserTest < ActiveSupport::TestCase

  test "requires a name" do
    @user = User.new(
      name: " ", 
      email: "antonino@example.com",
      password: "password"  
    )
    assert_not @user.valid?
    
    @user.name = "Antonino"
    assert @user.valid?
  end

  test "requires a valid email" do
    @user = User.new(
      name: "Antonino", 
      email: " ",
      password: "password"
    )
    assert_not @user.valid?
    
    @user.email = "invalid"
    assert_not @user.valid?
    
    @user.email = "antonino@example.com"
    assert @user.valid?
  end
    
  test "requires a unique email" do
    @existing_user = User.create(
      name: "Antonino",
      email: "nino@example.com",
      password: "password"
    )
    assert @existing_user.persisted?

    @user = User.new(
      name: "Nino", 
      email: "nino@example.com",
      password: "password"
    )
    assert_not @user.valid?
  end

  test "name and email is stripped of spaces before saving" do
    @user = User.create(
      name: " Antonino " ,
      email: " antonino@example.com ",

    )

    assert_equal "Antonino", @user.name
    assert_equal "antonino@example.com", @user.email
  end


  test " password length must be between 8 and ActiveModel's maximum" do
    @user = User.new(
      name: "Elena",
      email: "elena@example.com",
      password: ""
    )

    assert_not @user.valid?

    @user.password = "password"
    assert @user.valid?

    max_length = 
      ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
    @user.password = "a" * (max_length + 1)
    assert_not @user.valid?

  end


end
  