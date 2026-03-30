defmodule Helheim.Recaptcha do
  @moduledoc """
  Custom reCAPTCHA v2 verification module, replacing the unmaintained
  `recaptcha` hex package. Uses Req to call the Google reCAPTCHA
  verify API directly.
  """

  @verify_url "https://www.google.com/recaptcha/api/siteverify"

  @doc """
  Verifies a reCAPTCHA response token against the Google API.

  Returns `{:ok, response}` on success or `{:error, reasons}` on failure.

  ## Examples

      iex> Helheim.Recaptcha.verify("valid-token")
      {:ok, %{"success" => true}}

      iex> Helheim.Recaptcha.verify("invalid-token")
      {:error, ["invalid-input-response"]}

  """
  @spec verify(String.t()) :: {:ok, map()} | {:error, list(String.t())}
  def verify(response) do
    secret = Application.get_env(:helheim, :recaptcha)[:secret]

    body = URI.encode_query(%{secret: secret, response: response})

    case Req.post(@verify_url,
           body: body,
           headers: [{"content-type", "application/x-www-form-urlencoded"}]
         ) do
      {:ok, %Req.Response{status: 200, body: %{"success" => true} = resp_body}} ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: 200, body: %{"error-codes" => errors}}} ->
        {:error, errors}

      {:ok, %Req.Response{status: 200, body: _}} ->
        {:error, ["verification-failed"]}

      {:error, reason} ->
        {:error, [inspect(reason)]}
    end
  end

  @doc """
  Generates the HTML script tag and widget div for rendering
  the reCAPTCHA v2 checkbox on a page.

  ## Examples

      iex> Helheim.Recaptcha.render_widget()
      {:safe, _html_string}

  """
  @spec render_widget() :: {:safe, String.t()}
  def render_widget do
    config = Application.get_env(:helheim, :recaptcha)

    html =
      if config[:test_mode] do
        ~s(<input type="hidden" name="g-recaptcha-response" value="test_captcha_response">)
      else
        """
        <script src="https://www.google.com/recaptcha/api.js" async defer></script>
        <div class="g-recaptcha" data-sitekey="#{config[:public_key]}"></div>
        """
      end

    {:safe, html}
  end
end
