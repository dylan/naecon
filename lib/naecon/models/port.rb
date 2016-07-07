class Port
  attr_reader :id, :name

  def initialize(info)
    @id = info['Id'].to_i
    @name = info['Name']
  end

end
