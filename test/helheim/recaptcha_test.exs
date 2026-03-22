defmodule Helheim.RecaptchaTest do
  use ExUnit.Case, async: false
  import Mock

  alias Helheim.Recaptcha

  describe "verify/1" do
    test "returns {:ok, body} when Google responds with success" do
      response_body = %{"success" => true, "challenge_ts" => "2026-01-01T00:00:00Z", "hostname" => "helheim.dk"}

      with_mock Req, [post: fn(_url, _opts) ->
        {:ok, %Req.Response{status: 200, body: response_body}}
      end] do
        assert {:ok, ^response_body} = Recaptcha.verify("valid-token")

        assert_called Req.post(
          "https://www.google.com/recaptcha/api/siteverify",
          :_
        )
      end
    end

    test "returns {:error, error_codes} when Google responds with error codes" do
      response_body = %{"success" => false, "error-codes" => ["invalid-input-response"]}

      with_mock Req, [post: fn(_url, _opts) ->
        {:ok, %Req.Response{status: 200, body: response_body}}
      end] do
        assert {:error, ["invalid-input-response"]} = Recaptcha.verify("bad-token")
      end
    end

    test "returns {:error, ['verification-failed']} when success is false without error codes" do
      response_body = %{"success" => false}

      with_mock Req, [post: fn(_url, _opts) ->
        {:ok, %Req.Response{status: 200, body: response_body}}
      end] do
        assert {:error, ["verification-failed"]} = Recaptcha.verify("bad-token")
      end
    end

    test "returns {:error, [reason]} when the HTTP request fails" do
      with_mock Req, [post: fn(_url, _opts) ->
        {:error, %Req.TransportError{reason: :timeout}}
      end] do
        {:error, [reason]} = Recaptcha.verify("some-token")
        assert reason =~ "timeout"
      end
    end

    test "sends the configured secret and the response token in the request body" do
      secret = Application.get_env(:recaptcha, :secret)

      with_mock Req, [post: fn(_url, opts) ->
        expected_body = URI.encode_query(%{secret: secret, response: "my-token"})
        assert opts[:body] == expected_body
        assert {"content-type", "application/x-www-form-urlencoded"} in opts[:headers]
        {:ok, %Req.Response{status: 200, body: %{"success" => true}}}
      end] do
        Recaptcha.verify("my-token")
      end
    end
  end

  describe "render_widget/0" do
    test "returns a {:safe, html} tuple" do
      assert {:safe, html} = Recaptcha.render_widget()
      assert is_binary(html)
    end

    test "includes the Google reCAPTCHA script tag" do
      {:safe, html} = Recaptcha.render_widget()
      assert html =~ "https://www.google.com/recaptcha/api.js"
    end

    test "includes the g-recaptcha div with the configured public key" do
      public_key = Application.get_env(:recaptcha, :public_key)
      {:safe, html} = Recaptcha.render_widget()
      assert html =~ "g-recaptcha"
      assert html =~ "data-sitekey=\"#{public_key}\""
    end
  end
end
