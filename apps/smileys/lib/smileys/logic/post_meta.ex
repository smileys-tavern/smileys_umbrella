defmodule Smileys.Logic.PostMeta do

	def upload_image(image_data, tags) do
		upload_options = cond do
			String.length(tags) > 0 ->
				%{tags: String.split(tags, [", ", ","])}
			true ->
				%{}
		end

		uploaded_image = case Cloudex.upload(image_data.path, upload_options) do
			[ok: cloudinary] ->
				cloudinary
			[error: _] ->
				nil
		end

		{thumb, image} = cond do
			uploaded_image ->
				{Cloudex.Url.for(uploaded_image.public_id, %{width: 60, height: 60, format: "jpg"}), 
				 Cloudex.Url.for(uploaded_image.public_id, %{flags: "keep_iptc"})}
			true ->
				{nil, nil}
		end
		

		%{:image => image, :thumb => thumb}
	end

	def is_valid_upload(%{:content_type => content_type} = _image_data) do
		String.contains? content_type, ["image/png", "image/jpg", "image/jpeg", "image/gif", "image/JPG"]
	end

	def is_valid_upload(content_type) do
		String.contains? content_type, ["image/png", "image/jpg", "image/jpeg", "image/gif", "image/JPG"]
	end

	def process_tags(_meta, [], acc, acc_tags) do
		[{:tags, acc_tags}|acc]
	end

	def process_tags(meta, [tag|tail], acc, acc_tags) do
		case String.trim(tag) do
			"image" ->
				# TODO: thumbnail
				image_html = Phoenix.View.render_to_string SmileysWeb.SharedView, "image.html", %{:url => meta["link"]}
				process_tags(meta, tail, [{:post, image_html}|acc], acc_tags)
			"youtube" ->
				uri = URI.parse(meta["link"])
				url = URI.decode_query(uri.query)
				youtube_html = Phoenix.View.render_to_string SmileysWeb.SharedView, "embed_youtube.html", %{:hash => url["v"]}
				process_tags(meta, tail, [{:post, youtube_html}|acc], acc_tags)
			"vidme" ->
				url = String.replace(meta["link"], "vid.me", "vid.me/e")
				vidme_html = Phoenix.View.render_to_string SmileysWeb.SharedView, "embed_vidme.html", %{:url => url}
				process_tags(meta, tail, [{:post, vidme_html}|acc], acc_tags)
			"bmap" ->
				uri = URI.parse(meta["link"])
				url = URI.decode_query(uri.query)
				cond do
					url["cp"] ->
						bmap_html = Phoenix.View.render_to_string SmileysWeb.SharedView, "embed_bing_map.html", %{:coord => url["cp"], :position => String.replace(url["cp"], "~", "_")}
						process_tags(meta, tail, [{:post, bmap_html}|acc], acc_tags)
					true ->
						process_tags(meta, tail, acc, acc_tags)
				end
			_ ->
				# default is store it as a search term/nsfw etc
				case String.length(acc_tags) do
					0 ->
						process_tags(meta, tail, acc, String.trim(tag))
					_ ->
						process_tags(meta, tail, acc, acc_tags <> "," <> String.trim(tag))
				end			
		end
	end

	def process_tags(_post, nil) do
		[]
	end

	def process_tags(post, tags) do
		process_tags(post, String.split(tags, ",", trim: true), [], "")
	end

	def modify_post_by_meta_tags(post_body, tag_data) do
		case tag_data[:post] do
			nil ->
				post_body
			meta_markup ->
				meta_markup <> post_body
		end
	end
end