defmodule HelheimWeb.EmbedHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Format

  @url_regex ~r/(?<!["])(?:https?:\/\/)(?:[a-z0-9]+\.)?[a-z0-9]+\.(?:dk|com|net|de|org|be|io|tv)(?::\d+)?\/?(?:[a-z0-9-_\/?%&=;\.]+)?(?!["])/i

  @youtube_hosts ["youtube.com", "youtu.be"]
  @youtube_id_regex ~r/(youtu\.be\/|youtube\.com\/(watch\?(.*&)?v=|(embed|v)\/))([^\?&"'>]+)/i

  @giphy_hosts ["giphy.com"]
  @giphy_id_regex ~r/giphy\.com\/(?:(?:media|gifs)\/)?(?:[a-z-]{2,}-)?(.+?)(?:\/giphy)?(?:\.gif|$)/i

  @imgur_hosts ["imgur.com", "i.imgur.com"]
  @imgur_id_regex ~r/(gallery|a)?\/([a-zA-Z0-9]+?)\.?(?:jpg|png|gif)?$/i

  @vimeo_hosts ["vimeo.com"]
  @vimeo_id_regex ~r/\/(\d+)$/

  @spotify_hosts ["open.spotify.com"]
  @spotify_id_regex ~r/open.spotify.com\/(.+)/i

  @instagram_hosts ["instagram.com"]
  @instagram_id_regex ~r/\/p\/(.+)\//

  @gfycat_hosts ["gfycat.com"]
  @gfycat_id_regex ~r/gfycat.com\/(.+)/i

  @gafffa_hosts ["gafffa.dk"]
  @gafffa_id_regex ~r/gafffa\.dk\/(.+)/i

  @helheim_cloudfront_hosts ["d3ki6vg87hrfvz.cloudfront.net"]

  def replace_urls(content) do
    try do
      content =
        content
        |> text_to_html()
        |> safe_to_string()
      Regex.replace(@url_regex, content, &(replace_url(&1)))
      |> raw()
    rescue
      _ -> text_to_html(content)
    end
  end

  def raw_replace_urls(content) do
    try do
      Regex.replace(@url_regex, content, &(replace_url(&1)))
      |> raw()
    rescue
      _ -> raw(content)
    end
  end

  defp replace_url(match) do
    %{host: host} = URI.parse(match)
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
      String.contains?(host, @spotify_hosts) ->
        replace_spotify(match)
      String.contains?(host, @instagram_hosts) ->
        replace_instagram(match)
      String.contains?(host, @gfycat_hosts) ->
        replace_gfycat(match)
      String.contains?(host, @gafffa_hosts) ->
        replace_gafffa(match)
      true ->
        autolink(match)
    end
  end

  def replace_youtube(nil), do: ""
  def replace_youtube(match) do
    try do
      [_,_,_,_,_,id] = Regex.run(@youtube_id_regex, match)
      """
      <div class="embed-responsive embed-responsive-16by9">
        <iframe class="embed-responsive-item" width="560" height="315" src="https://www.youtube-nocookie.com/embed/#{id}?rel=0" frameborder="0" allowfullscreen></iframe>
      </div>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_giphy(nil), do: ""
  def replace_giphy(match) do
    try do
      [_,id] = Regex.run(@giphy_id_regex, match)
      """
      <div class="embed-responsive embed-responsive-1by1">
        <iframe src="//giphy.com/embed/#{id}?hideSocial=true" width="480" height="600" frameborder="0" class="giphy-embed embed-responsive-item" allowfullscreen=""></iframe>
      </div>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_imgur(nil), do: ""
  def replace_imgur(match) do
    try do
      [_,prefix,id] = Regex.run(@imgur_id_regex, match)
      cond do
        prefix != "" ->
          """
          <blockquote class="imgur-embed-pub" lang="en" data-id="a/#{id}"><a href="//imgur.com/#{id}"></a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>
          """
        true ->
          """
          <blockquote class="imgur-embed-pub" lang="en" data-id="#{id}"><a href="//imgur.com/#{id}"></a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>
          """
      end
    rescue
      _ -> autolink(match)
    end
  end

  def replace_vimeo(nil), do: ""
  def replace_vimeo(match) do
    try do
      [_,id] = Regex.run(@vimeo_id_regex, match)
      """
      <div class="embed-responsive embed-responsive-16by9">
        <iframe class="embed-responsive-item" src="https://player.vimeo.com/video/#{id}?color=ffffff&title=0&byline=0&portrait=0" width="640" height="268" frameborder="0" allowfullscreen></iframe>
      </div>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_spotify(nil), do: ""
  def replace_spotify(match) do
    try do
      [_,id] = Regex.run(@spotify_id_regex, match)
      """
      <div>
        <iframe src="https://open.spotify.com/embed/#{id}" width="300" height="380" frameborder="0" allowtransparency="true" allow="encrypted-media"></iframe>
      </div>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_instagram(nil), do: ""
  def replace_instagram(match) do
    try do
      [_,id] = Regex.run(@instagram_id_regex, match)
      """
      <a href="#{match}" target="_blank">
        <img src="https://instagram.com/p/#{id}/media/?size=t" class="img-fluid" alt="">
      </a>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_gfycat(nil), do: ""
  def replace_gfycat(match) do
    try do
      [_,id] = Regex.run(@gfycat_id_regex, match)
      """
      <div style='position:relative; padding-bottom:42.50%'>
        <iframe src='https://gfycat.com/ifr/#{id}' frameborder='0' scrolling='no' width='100%' height='100%' style='position:absolute;top:0;left:0;' allowfullscreen></iframe>
      </div>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_gafffa(nil), do: ""
  def replace_gafffa(match) do
    try do
      [_,id] = Regex.run(@gafffa_id_regex, match)
      """
      <a href="#{match}" target="_blank">
        #{String.replace(match, "gafffa.dk", "gaffa.dk")}
      </a>
      """
    rescue
      _ -> autolink(match)
    end
  end

  def replace_helheim_cloudfront(nil), do: ""
  def replace_helheim_cloudfront(match) do
    try do
      """
      <img src="#{match}" class="img-fluid" alt="">
      """
    rescue
      _ -> autolink(match)
    end
  end

  def autolink(nil), do: ""
  def autolink(match) do
    try do
      """
      <a href="#{match}" target="_blank">#{match}</a>
      """
    rescue
      _ -> match
    end
  end
end
