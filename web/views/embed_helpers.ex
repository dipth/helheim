defmodule Helheim.EmbedHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Format
  import Phoenix.HTML.Link
  alias Phoenix.HTML.Safe

  @url_regex ~r/((?:http|https):\/\/)?([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-;]*[\w@?^=%&\/~+#-])?/i

  @youtube_hosts ["youtube.com", "youtu.be"]
  @youtube_id_regex ~r/(youtu\.be\/|youtube\.com\/(watch\?(.*&)?v=|(embed|v)\/))([^\?&"'>]+)/i

  @giphy_hosts ["giphy.com"]
  @giphy_id_regex ~r/giphy\.com\/(?:(?:media|gifs)\/)?(?:[a-z-]{2,}-)?(.+?)(?:\/giphy)?(?:\.gif|$)/i

  @imgur_hosts ["imgur.com"]
  @imgur_id_regex ~r/imgur\.com\/(gallery|a)\/(.+)/i

  @vimeo_hosts ["vimeo.com"]
  @vimeo_id_regex ~r/\/(\d+)$/

  @helheim_cloudfront_hosts ["d3ki6vg87hrfvz.cloudfront.net"]

  def replace_urls(content) do
    content =
      content
      |> text_to_html()
      |> safe_to_string()
    Regex.replace(@url_regex, content, &(replace_url(&1, &2, &3, &4)))
    |> raw()
  end

  defp replace_url(match, _protocol, host, _path) do
    match
    cond do
      String.contains?(host, @youtube_hosts) ->
        replace_youtube(match)
      String.contains?(host, @giphy_hosts) ->
        replace_giphy(match)
      String.contains?(host, @imgur_hosts) ->
        replace_imgur(match)
      String.contains?(host, @vimeo_hosts) ->
        replace_vimeo(match)
      String.contains?(host, @helheim_cloudfront_hosts) ->
        replace_helheim_cloudfront(match)
      true ->
        autolink(match)
    end
  end

  def replace_youtube(nil), do: ""
  def replace_youtube(match) do
    [_,_,_,_,_,id] = Regex.run(@youtube_id_regex, match)
    """
    <div class="embed-responsive embed-responsive-16by9">
      <iframe class="embed-responsive-item" width="560" height="315" src="https://www.youtube-nocookie.com/embed/#{id}?rel=0" frameborder="0" allowfullscreen></iframe>
    </div>
    """
  end

  def replace_giphy(nil), do: ""
  def replace_giphy(match) do
    [_,id] = Regex.run(@giphy_id_regex, match)
    IO.inspect Regex.run(@giphy_id_regex, match)
    """
    <div class="embed-responsive embed-responsive-1by1">
      <iframe src="//giphy.com/embed/#{id}?hideSocial=true" width="480" height="600" frameborder="0" class="giphy-embed embed-responsive-item" allowfullscreen=""></iframe>
    </div>
    """
  end

  def replace_imgur(nil), do: ""
  def replace_imgur(match) do
    [_,_type,id] = Regex.run(@imgur_id_regex, match)
    """
    <blockquote class="imgur-embed-pub" lang="en" data-id="a/#{id}"><a href="//imgur.com/#{id}"></a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>
    """
  end

  def replace_vimeo(nil), do: ""
  def replace_vimeo(match) do
    [_,id] = Regex.run(@vimeo_id_regex, match)
    """
    <div class="embed-responsive embed-responsive-16by9">
      <iframe class="embed-responsive-item" src="https://player.vimeo.com/video/#{id}?color=ffffff&title=0&byline=0&portrait=0" width="640" height="268" frameborder="0" allowfullscreen></iframe>
    </div>
    """
  end

  def replace_helheim_cloudfront(nil), do: ""
  def replace_helheim_cloudfront(match) do
    """
    <img src="#{match}" class="img-fluid" alt="">
    """
  end

  def autolink(nil), do: ""
  def autolink(match) do
    """
    <a href="#{match}" target="_blank">#{match}</a>
    """
  end
end
