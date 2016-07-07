# Represents an item.
class Item
  def initialize(info)
    # @info = info
    type_filter = %w( LootTable
                      TopPlayersLetter
                      Recipe
                      Cannon
                      Ship
                      ConquestFlag
                      Building
                      ExtraXpUsableItem
                      ExtraLaborHoursUsableItem
                      EventSpawnerItem
                      LootContainer
                      ModulesContainer
                      DefaultUsableItem )

    module_type_filter = %w(Hidden)

    name_filter = %w( 'Cannon nation module'
                      OLD
                      Default
                      TEST )

    is_item_type = type_filter.any? { |s| info['ItemType']&.include? s }
    has_names    = name_filter.any? { |s| info['Name']&.include? s }
    has_module   = module_type_filter.any? { |s| info['ModuleType']&.include? s }
    # puts has_names
    # puts has_module
    if is_item_type || has_names || has_module
      raise StandardError, 'Invalid Item'
    end

    @id              = info['Id']
    @name            = info['Name']
    @base_price      = info['BasePrice']


    @eu_trader_price = info['BasePrice'] * 3 + 1 if info['scoreValue'].nil?
    @quality = get_quality(info['scoreValue']) unless info['scoreValue'].nil?

  end

  def get_quality(value)
    case value
    when 0
      return :Basic
    when 0..20
      return :Common
    when 20..50
      return :Fine
    when 50..80
      return :MasterCraft
    when 80..100
      return :Exceptional
    end
  end
end
