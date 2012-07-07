class Nominee < ActiveRecord::Base
  # Fields
  field :name,:image_url, :github_id, :twitter_id
  field :description, as: :text

  # Validations
  validates_presence_of :name, :description

  # Referenced
  has_many :ballots

  class << self

    def search(account, provider=:github)
      self.send("search_#{provider}", account)
    end

    def find_by_account(account)
      t = self.arel_table
      account = self.where(t[:github_id].eq(account).or(t[:twitter_id].eq(account))).first
      raise ActiveRecord::RecordNotFound if account.nil?
      account
    end

    private

    def search_twitter(account)
      info = Twitter.user(account)
      new do |user|
        user.name = info.name
        user.image_url = info.profile_image_url(:original)

        user.twitter_id = account
      end
    end

    def search_github(account)
      info = Octokit.user(account)
      new do |user|
        user.name = info["name"]
        user.image_url = info["avatar_url"]

        user.github_id = account
      end
    end

  end

  def account
    [github_id, twitter_id].reject(&:blank?).first
  end

  def find_or_new(user)
    self.ballots.find_by_user_id(user) || self.ballots.new(user: user)
  end

end
