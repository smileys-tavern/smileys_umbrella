defmodule Smileyscaretaker.Feeds do
	alias Smileyscaretaker.Structs.SmileysFeed
	alias SmileysData.{QueryRoom, QueryPost, QueryPostMeta, RegisteredBot, QueryUser}
	alias SmileysData.State.Room.ActivityRegistry, as: RoomActivityRegistry
	alias SmileysData.State.Room.Activity, as: RoomActivity

	def create_post_from_feed(%SmileysFeed{img: img_url, categories: tags, link: feed_url, author: author} = feed, %RegisteredBot{username: bot_username, callback_module: callback_module}) do
		# Check whether it exists based on feed_url and do not process duplicate
		case QueryPostMeta.postmeta_by_link(feed_url) do
			nil ->
				bot_user_alias = QueryUser.user_by_name(bot_username)

		      	room = QueryRoom.room(callback_module)

				post = %{
					"title" => feed.title,
		        	"posterid" => bot_user_alias.id,
		        	"voteprivate" => bot_user_alias.reputation,
		        	"votepublic"  => 0,
		        	"hash" => QueryPost.create_hash(bot_user_alias.id, room.name),
		        	"superparentid" => room.id,
		        	"parentid" => room.id,
		        	"parenttype" => "room",
		        	"age" => room.age,
		        	"body" => feed.summary
			    }

			    tags_final = case author do
			    	nil ->
			    		tags
			    	"" ->
			    		tags
			    	_ ->
			    		[author|tags]
			    end

			    image_upload = case img_url do
			    	nil ->
			    		nil
			    	_ ->
			    		upload_feed_image(img_url, tags_final)
			    end

			    meta_params = %{
			    	"link" => feed_url,
			    	"tags" => case tags_final do 
			    		[_,_|_] -> 
			    			String.replace(Enum.join(tags_final, ", "), ~r/[\-\.'’";]/, "")
			    		[tag|_] ->
			    			String.replace(tag, ~r/[\-\.'’";]/, "")
			    		_ ->
			    			""
			    	end
			    }

			    case QueryPost.create_new_post(bot_user_alias, post, meta_params, image_upload) do
			    	{:ok, post} ->
			    		room_activity = RoomActivityRegistry.increment_room_bucket_activity!(
			              {:via, :syn, :room_activity_reg},
			              room.name,
			              %RoomActivity{new_posts: 1}
			            )

			            SmileyscaretakerWeb.Endpoint.broadcast("room:" <> room.name, "activity_external", %{"room" => room.name, "activity" => room_activity})

			    		{:ok, post}
			    	{:error, error} ->
			    		{:error, error}
			    end
			_ ->
				{:ok, {:duplicate, %{}}}
		end
	end

	def map_feed(%{entries: entries}) do
  	  	map_feed(entries, [], 0)
    end

  	# ran out of stories
  	defp map_feed([], acc, _) do
  		acc
  	end

 	 # ran out of patience
 	defp map_feed(_, acc, 3) do
  		acc
  	end

  	defp map_feed([%FeederEx.Entry{author: nil} = feeds|tail], acc, count) do
  		map_feed([%{feeds | :author => ""}|tail], acc, count)
  	end

  	defp map_feed([%FeederEx.Entry{author: author, categories: categories, enclosure: enclosure, id: id, link: link, title: title, summary: summary, updated: date_string}|tail], acc, count) do
  		img = case enclosure do
  			nil ->
  				nil
  			%{:url => img_url} ->
  				img_url
  		end

  		# normalize categories to List
  		categories_checked = case categories do
  			[] ->
  				[]
  			[_|_] ->
  				categories
  			nil ->
  				[]
  			_ ->
  				[categories]
  		end

  		url = case link do
  			nil ->
  				id
  			_ ->
  				link
  		end

  		summary_formated = case summary do
  			nil ->
  				summary
  			_ ->
  				String.replace(summary, "\n", "<br />")
  		end

  		entry = %SmileysFeed{
  			author: author,
  			title: title,
  			categories: categories_checked,
  			img: img,
  			date: date_string,
  			link: url,
  			summary: summary_formated
  		}
  		map_feed(tail, [entry|acc], count + 1)
  	end

  	defp map_feed([feed|tail], acc, count) do
  		IO.inspect "No map found for feed"
  		IO.inspect feed
  		map_feed(tail, acc, count)
  	end

	def upload_feed_image(url, tags) do
		upload_options = %{tags: tags}

		uploaded_image = case Cloudex.upload(url, upload_options) do
			[ok: cloudinary] ->
				cloudinary
			[error: _error] ->
				nil
		end

		{thumb, image} = cond do
			uploaded_image ->
				{Cloudex.Url.for(uploaded_image.public_id, %{width: 60, height: 60, format: "jpg"}), nil}
			true ->
				{nil, nil}
		end
		

		%{:image => image, :thumb => thumb}
	end
end