class Photo

  def mongo_client
    Mongoid::Clients.default
  end
end
