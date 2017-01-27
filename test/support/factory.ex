defmodule Helheim.Factory do
  use ExMachina.Ecto, repo: Helheim.Repo

  def user_factory do
    %Helheim.User{
      name: "Some User",
      username: sequence(:username, &"foobar-#{&1}"),
      email: sequence(:email, &"foo-#{&1}@bar.com"),
      password_hash: "$2b$12$Zc2AexPqKCRDCybgOJ28dOBJSGOd70xYSdyS2fb/vZbRQ/dhAnCym", # "password"
      confirmation_token: "ZUhtaHI4R29mZVdYSjdVRUNvMWhzZz09",
      confirmed_at: DateTime.utc_now
    }
  end

  def blog_post_factory do
    %Helheim.BlogPost{
      user: build(:user),
      title: "My Awesome Title",
      body: "My Aweseome Text"
    }
  end

  def profile_comment_factory do
    %Helheim.Comment{
      author: build(:user),
      profile: build(:user),
      body: "My Aweseome Comment"
    }
  end
end
