defmodule SmileysProcesses.Emails.UserActivityCompose do
  import Bamboo.Email

  alias SmileysData.Query.User.Subscription, as: QuerySubscription

  alias SmileysData.State.Activity
  alias SmileysData.State.Room.Activity, as: RoomActivity
  alias SmileysData.State.User.Activity, as: UserActivity
  alias SmileysData.State.User.Notification, as: UserNotification


  def daily(user) do
    activity = Activity.retrieve(%UserActivity{user_name: user.name})

    activity_list = Enum.map(activity, fn {_, activity} -> activity end)

    subscriptions = QuerySubscription.get(user)

    subscriptions_decorated = List.foldl(subscriptions, [], fn(subscription, acc) -> 
      room_activity = Activity.retrieve_item(%RoomActivity{room: subscription.roomname})

      [Map.merge(subscription, room_activity)|acc]
    end)

    base_email(user)
      |> subject("Smileys Pub Daily")
      |> html_body(get_email_html("Daily", user, activity_list, subscriptions_decorated))
  end

  def weekly(user) do
    activity = Activity.retrieve(%UserActivity{user_name: user.name})

    activity_list = Enum.map(activity, fn {_, activity} -> activity end)

    subscriptions = QuerySubscription.get(user)

    subscriptions_decorated = List.foldl(subscriptions, [], fn(subscription, acc) -> 
      room_activity = Activity.retrieve_item(%RoomActivity{room: subscription.roomname})

      [Map.merge(subscription, room_activity)|acc]
    end)

    base_email(user)
      |> subject("Smileys Pub Weekly")
      |> html_body(get_email_html("Weekly", user, activity_list, subscriptions_decorated))
  end

  defp base_email(user) do
    new_email()
      |> from("Smileys Pub<no-reply@smileys.pub>")
      |> to(user.email)
  end

  def get_email_html(type, user, user_activity, user_subscriptions) do
    user_activity_html = if !Enum.empty?(user_activity) do
      user_activity_html_entries = for activity <- user_activity do
        case activity do 
          %UserActivity{} ->
            get_user_activity_html(activity)
          %UserNotification{} ->
            get_user_notification_html(activity)
        end
      end

      Enum.join(user_activity_html_entries)
    else
      "<strong>No Recent activity on your posts and you were not pinged</strong>"
    end

    subscriptions_html = get_subscriptions_html(user_subscriptions)

    user_name = user.name

    ~s"""
    <h2>Smileys Pub #{type}</h2>

    <div class="sidebar">
      <div class="userlatestposts sidebar-links site-actions">
        <h5>Your Latest</h5>
        #{user_activity_html}
      </div>

      <div class="sidebar-links subscriptions">
        <h5>Your Subscriptions</h5>
        #{subscriptions_html}
      </div>

      <div class="sidebar-links">
        <h5>Manage email settings</h5>
        <div class="room-link">
          <a href="https://smileys.pub/u/#{user_name}/settings">/u/#{user_name} Settings</a>
        </div>
      </div>
    </div>
    """
  end

  def get_user_activity_html(activity) do
    hash = Map.get(activity, :hash)
    url = Map.get(activity, :url)
    comments = Map.get(activity, :comments)
    votes = Map.get(activity, :votes)

    ~s"""
      <a class="user-activity activity-container" id="user-activity-#{hash}" 
      href="https://smileys.pub/#{url}">
      <span class="user-activity-comment activity-count" data-hover="Reply">#{comments}</span>
      <span class="user-activity-vote activity-count" data-hover="Vote">#{votes}</span>
      <span class="user-activity-url">#{url}</span>
      </a>
    """
  end

  def get_user_notification_html(notification) do
    hash = Map.get(notification, :hash)
    url = Map.get(notification, :url)
    pinged_by = String.slice(Map.get(notification, :pinged_by), 0, 30)
    url_condensed = String.slice(Map.get(notification, :url), 0, 30)

    ~s"""
      <a class="user-activity user-activity-notification activity-container" id="user-activity-#{hash}" 
      href="https://smileys.pub/#{url}">
      <span class="user-activity-pingedby">#{pinged_by}</span>
      <span class="user-activity-url">#{url_condensed}</span>
      </a>
    """
  end

  def get_subscriptions_html(subscriptions) do
    if !Enum.empty?(subscriptions) do
      subscriptions_html_entries = for subscription <- subscriptions do
        room_name = subscription.roomname
        new_posts = subscription.new_posts
        new_subs = subscription.subs

        ~s"""
          <div class="room-link room-#{room_name} activity-container">
          <span class="room-activity-#{room_name}">
          <span class="room-activity-new-posts activity-count" data-hover="New Posts">
            #{new_posts}
          </span>
        
          <span class="room-activity-subs activity-count" data-hover="New Subs">#{new_subs}</span>
          </span>
          <a href="https://smileys.pub/r/#{room_name}">/r/#{room_name}</a>
          </div>
      """
    end

    Enum.join(subscriptions_html_entries)
    else
      "<strong>No Subscriptions! Subscribe to a room and you can keep up with new goings on</strong>"
    end
  end
end
