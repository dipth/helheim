defmodule Helheim.Factory do
  use ExMachina.Ecto, repo: Helheim.Repo

  def user_factory do
    %Helheim.User{
      name: "Some User",
      username: sequence(:username, &"foobar-#{&1}"),
      email: sequence(:email, &"foo-#{&1}@bar.com"),
      password_hash: "$2b$12$Zc2AexPqKCRDCybgOJ28dOBJSGOd70xYSdyS2fb/vZbRQ/dhAnCym", # "password"
      confirmation_token: "ZUhtaHI4R29mZVdYSjdVRUNvMWhzZz09",
      confirmed_at: DateTime.utc_now,
      profile_text: "Foo Bar"
    }
  end

  def blog_post_factory do
    %Helheim.BlogPost{
      user: build(:user),
      title: "My Awesome Title",
      body: "My Aweseome Text"
    }
  end

  def blog_post_comment_factory do
    %Helheim.Comment{
      author: build(:user),
      blog_post: build(:blog_post),
      body: "My Aweseome Comment"
    }
  end

  def profile_comment_factory do
    %Helheim.Comment{
      author: build(:user),
      profile: build(:user),
      body: "My Aweseome Comment"
    }
  end

  def notification_factory do
    %Helheim.Notification{
      user: build(:user),
      title: "Some Notification!",
      icon: "foo",
      path: "/"
    }
  end

  def private_message_factory do
    %Helheim.PrivateMessage{
      sender: build(:user),
      recipient: build(:user),
      body: "Awesome Message Text"
    }
  end

  def photo_album_factory do
    %Helheim.PhotoAlbum{
      user: build(:user),
      title: "My Photo Album",
      description: "Full of photos",
      visibility: "public"
    }
  end

  def photo_factory do
    %Helheim.Photo{
      photo_album: build(:photo_album),
      uuid: sequence(:uuid, &"5976423a-ee35-11e3-8569-14109ff1a30#{&1}")
    }
  end

  def forum_category_factory do
    %Helheim.ForumCategory{
      title: "A Category",
      description: "A Description"
    }
  end

  def forum_factory do
    %Helheim.Forum{
      forum_category: build(:forum_category),
      title: "A Forum",
      description: "A Description",
      locked: false
    }
  end

  def forum_topic_factory do
    %Helheim.ForumTopic{
      forum: build(:forum),
      user: build(:user),
      title: "A Topic",
      body: "Some Content"
    }
  end

  def forum_reply_factory do
    %Helheim.ForumReply{
      forum_topic: build(:forum_topic),
      user: build(:user),
      body: "Some Content"
    }
  end

  def term_factory do
    %Helheim.Term{
      body: "Some Content",
      published: false
    }
  end
end
