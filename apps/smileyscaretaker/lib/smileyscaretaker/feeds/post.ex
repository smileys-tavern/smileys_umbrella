defmodule Smileyscaretaker.Feeds.Post do
	alias Smileyscaretaker.Structs.SmileysFeed
	
	alias SmileysData.Query.Post, as: QueryPost
	alias SmileysData.Query.Post.Helper, as: QueryPostHelper
	alias SmileysData.Query.Room, as: QueryRoom 
	alias SmileysData.Query.Post.Meta, as: QueryPostMeta
	alias SmileysData.Query.User, as: QueryUser
	alias SmileysData.RegisteredBot
	
	alias SmileysData.State.Activity
	alias SmileysData.State.Room.Activity, as: RoomActivity
	alias SmileysData.{Room, User}

	def create_post_from_feed(%SmileysFeed{link: feed_url, title: title, summary: summary} = feed, %RegisteredBot{username: bot_username, callback_module: room_name}) do
		# Check whether it exists based on feed_url and do not process duplicate
		case QueryPostMeta.by_link(feed_url) do
			nil ->
				bot_user_alias = QueryUser.by_name(bot_username)

                %User{id: bot_user_id, reputation: bot_user_rep} = bot_user_alias
		      	%Room{id: room_id, age: room_age, name: room_name} = QueryRoom.by_name(room_name)

				post = %{
					"title" => title,
		        	"posterid" => bot_user_id,
		        	"voteprivate" => bot_user_rep,
		        	"votepublic"  => 0,
		        	"hash" => QueryPostHelper.create_hash(bot_user_id, room_name),
		        	"superparentid" => room_id,
		        	"parentid" => room_id,
		        	"parenttype" => "room",
		        	"age" => room_age,
		        	"body" => summary
			    }

			    {:ok, tags_list, tags_string} = map_tags(feed)

			    {:ok, image_upload} = map_image_upload(feed, tags_list)

			    {:ok, meta_params} = map_meta_params(feed, tags_string)

			    case QueryPost.create_new(bot_user_alias, post, meta_params, image_upload) do
			    	{:ok, post} ->
			    		_room_activity = Activity.update_item(%RoomActivity{new_posts: 1, room: room_name})

			    		{:ok, post}
			    	{:error, error} ->
			    		{:error, error}
			    end
			_ ->
				{:ok, {:duplicate, %{}}}
		end
	end

	defp map_meta_params(%SmileysFeed{link: feed_url}, tags_string) do
	  {:ok, %{"link" => feed_url, "tags" => tags_string}}
	end

	defp map_image_upload(%SmileysFeed{img: nil}, _) do
	  {:ok, nil}
	end

	defp map_image_upload(%SmileysFeed{img: img_url}, tags_list) do
	  {:ok, upload_feed_image(img_url, tags_list)}
	end

	defp map_tags(%SmileysFeed{author: author, categories: tags}) do
      tags_to_list = cond do
      	is_list(tags) ->
      	  tags
      	true ->
      	  []
      end

      tags_list = case author do
	    nil ->
		  tags_to_list
	    "" ->
	      tags_to_list
	    _ ->
	      [author|tags_to_list]
	  end

	  # Scrub all tags
	  tags_list_scrubbed = Enum.reduce(Enum.reverse(tags_list), [], fn(tag, acc) ->
	    case Regex.replace(~r/[^a-zA-Z0-9, :]/, tag, "") do
	      "" ->
	        acc
	      scrubbed ->
	      	[scrubbed|acc]
	    end
	  end)

	  tags_string = Enum.join(Enum.slice(tags_list_scrubbed, 0, 7), ", ")

	  {:ok, tags_list, tags_string}
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