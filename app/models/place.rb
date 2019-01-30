class Place
  attr_accessor :id, :formatted_address, :location, :address_components
  
  def initialize(params = {})
    @id = params[:_id].to_s
    @address_components = []
    params[:address_components].each do |ac|
      temp = AddressComponent.new(ac)
      @address_components.push(temp)
    end
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:location])
  end
  
  def self.mongo_client
    Mongoid::Clients.default
  end
  
  def self.collection
    self.mongo_client['places']
  end
  
  def self.load_all file_path
    file = File.read(file_path)
    self.collection.insert_many( JSON.parse(file))
  end
  
  def self.find_by_short_name sn
    self.collection.find({"address_components.short_name" => sn})
  end
  
  def self.to_places hash
    places = []
    hash.each { |h| places.push(Place.new(h)) }
    return places
  end
  
  def self.find id
    id = BSON::ObjectId.from_string(id)
    result = self.collection.find(:_id => id).first
    return result.nil? ? nil : Place.new(result)
  end
  
  def self.all(offset = 0, limit = nil)
    result = self.collection.find().skip(offset)
    result = result.limit(limit) if limit
    result_array = []
    result.each { |r| result_array.push(Place.new(r)) }
    return result_array
  end
  
  def destroy
    _id = BSON::ObjectId.from_string(@id)
    self.class.collection.find(_id: _id).delete_one 
  end
end
