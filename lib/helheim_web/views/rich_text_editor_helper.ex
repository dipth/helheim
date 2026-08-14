defmodule HelheimWeb.RichTextEditorHelper do
  @moduledoc """
  Renders a textarea wired up for the TipTap rich text editor
  (assets/js/rich_text_editor.js), carrying the editor configuration and
  gettext'ed UI labels as data attributes.
  """

  use Gettext, backend: HelheimWeb.Gettext
  import PhoenixHTMLHelpers.Form, only: [textarea: 3]

  def rich_textarea(form, field, opts \\ []) do
    textarea(form, field,
      class: "form-control",
      rows: Keyword.get(opts, :rows, 10),
      data: [
        rich_text_editor: "true",
        mentions: to_string(Keyword.get(opts, :mentions, false)),
        asset_host: Application.get_env(:waffle, :asset_host),
        labels: Jason.encode!(labels())
      ]
    )
  end

  defp labels do
    %{
      undo: gettext("Undo"),
      redo: gettext("Redo"),
      bold: gettext("Bold"),
      italic: gettext("Italic"),
      strike: gettext("Strikethrough"),
      superscript: gettext("Superscript"),
      subscript: gettext("Subscript"),
      alignLeft: gettext("Align left"),
      alignCenter: gettext("Align center"),
      alignRight: gettext("Align right"),
      alignJustify: gettext("Justify"),
      bulletList: gettext("Bullet list"),
      orderedList: gettext("Numbered list"),
      blockquote: gettext("Quote"),
      horizontalRule: gettext("Horizontal line"),
      link: gettext("Link"),
      image: gettext("Image"),
      paragraph: gettext("Paragraph"),
      heading: gettext("Heading"),
      linkPrompt: gettext("Link URL:"),
      imagePrompt: gettext("Image URL:"),
      externalImageWarning:
        gettext(
          "This image is hosted outside %{host} and will be removed when the content is saved. Insert it anyway?",
          host: Application.get_env(:waffle, :asset_host)
        )
    }
  end
end
