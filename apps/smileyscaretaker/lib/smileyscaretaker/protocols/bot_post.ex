defprotocol Smileyscaretaker.Protocols.BotPost do
  @fallback_to_any false

  @doc """
  Create a post based on an accumulated bot payload
  """
  def create(bot_payload)
end

defimpl Smileyscaretaker.Protocols.BotPost, for: SmileysData.Structs.SmileysFeed do
  #alias Smileyscaretaker.Structs.SmileysFeed

  #def create(%SmileysFeed{author: author, title: title, categories: categories, img: img, date: date, link: link}, %SmileysBot{} = bot) do
  #
  #end
end