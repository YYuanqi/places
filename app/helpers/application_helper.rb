module ApplicationHelper
  def self.to_places hash
    places = []
    hash.each { |h| places.push(Place.new(h)) }
    return places
  end
end
