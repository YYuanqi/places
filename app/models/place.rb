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
  
    def self.take
    a = {_id: BSON::ObjectId('56521833e301d0284000003d'),
        address_components:
          [
          {long_name:"Wilsden", short_name:"Wilsden", types:["administrative_area_level_4", "political"]},
          {long_name:"Bradford District", short_name:"Bradford District", types:["administrative_area_level_3", "political"]}
          ],
        formatted_address:"Wilsden, West Yorkshire, UK",
        geometry:
          {
          location:{lat:53.8256035, lng:-1.8625303},
          geolocation:{type:"Point", coordinates:[-1.8625303, 53.8256035]}
          }
        }
      return a
    end
end
