extends Node
class_name TradingSystemClass
## Manages all trading functionality - shops, inventories, prices, haggling, and special deals
## Handles NPC shops, wandering merchants, and player-to-player trading

signal trade_started(trader_id: String, trader_type: int)
signal trade_completed(trader_id: String, total_value: int)
signal trade_cancelled(trader_id: String)
signal item_purchased(item_id: String, quantity: int, price: int)
signal item_sold(item_id: String, quantity: int, price: int)
signal special_deal_available(trader_id: String, deal: Dictionary)
signal haggle_success(item_id: String, discount: float)
signal haggle_failed(item_id: String)
signal trader_restocked(trader_id: String)
signal currency_changed(old_amount: int, new_amount: int)

# ============================================================================
# TRADING CONFIGURATION
# ============================================================================

enum TraderType {
	GENERAL_STORE,
	WEAPONS_DEALER,
	MEDIC,
	MECHANIC,
	BLACK_MARKET,
	WANDERING_MERCHANT,
	FARMER,
	CRAFTSMAN,
	MILITARY_SURPLUS,
	SCIENTIST,
}

enum CurrencyType {
	COINS,
	TRADE_NOTES,
	MILITARY_SCRIP,
	RESEARCH_CREDITS,
}

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

const TRADER_DEFINITIONS := {
	TraderType.GENERAL_STORE: {
		"name": "General Store",
		"description": "Everyday supplies and basic necessities.",
		"buy_modifier": 1.0,
		"sell_modifier": 0.5,
		"currency": CurrencyType.COINS,
		"restock_hours": 24,
		"inventory_pool": "general",
		"special_deal_chance": 0.1,
	},
	TraderType.WEAPONS_DEALER: {
		"name": "Weapons Dealer",
		"description": "Firearms, ammunition, and combat gear.",
		"buy_modifier": 1.2,
		"sell_modifier": 0.6,
		"currency": CurrencyType.COINS,
		"restock_hours": 48,
		"inventory_pool": "weapons",
		"special_deal_chance": 0.15,
	},
	TraderType.MEDIC: {
		"name": "Medic",
		"description": "Medical supplies and healing services.",
		"buy_modifier": 0.9,
		"sell_modifier": 0.4,
		"currency": CurrencyType.COINS,
		"restock_hours": 12,
		"inventory_pool": "medical",
		"special_deal_chance": 0.05,
	},
	TraderType.MECHANIC: {
		"name": "Mechanic",
		"description": "Vehicle parts, fuel, and repair services.",
		"buy_modifier": 1.1,
		"sell_modifier": 0.55,
		"currency": CurrencyType.COINS,
		"restock_hours": 36,
		"inventory_pool": "vehicle_parts",
		"special_deal_chance": 0.1,
	},
	TraderType.BLACK_MARKET: {
		"name": "Black Market",
		"description": "Rare and illegal goods at premium prices.",
		"buy_modifier": 1.5,
		"sell_modifier": 0.7,
		"currency": CurrencyType.COINS,
		"restock_hours": 72,
		"inventory_pool": "black_market",
		"special_deal_chance": 0.25,
	},
	TraderType.WANDERING_MERCHANT: {
		"name": "Wandering Merchant",
		"description": "A mysterious trader with eclectic goods.",
		"buy_modifier": 1.3,
		"sell_modifier": 0.65,
		"currency": CurrencyType.COINS,
		"restock_hours": 168,  # Weekly
		"inventory_pool": "rare_goods",
		"special_deal_chance": 0.3,
	},
	TraderType.FARMER: {
		"name": "Farmer",
		"description": "Fresh food and agricultural supplies.",
		"buy_modifier": 0.8,
		"sell_modifier": 0.4,
		"currency": CurrencyType.COINS,
		"restock_hours": 8,
		"inventory_pool": "farm",
		"special_deal_chance": 0.05,
	},
	TraderType.CRAFTSMAN: {
		"name": "Craftsman",
		"description": "Tools, materials, and crafting supplies.",
		"buy_modifier": 1.0,
		"sell_modifier": 0.5,
		"currency": CurrencyType.COINS,
		"restock_hours": 24,
		"inventory_pool": "crafting",
		"special_deal_chance": 0.1,
	},
	TraderType.MILITARY_SURPLUS: {
		"name": "Military Surplus",
		"description": "Military-grade equipment and supplies.",
		"buy_modifier": 1.4,
		"sell_modifier": 0.6,
		"currency": CurrencyType.MILITARY_SCRIP,
		"restock_hours": 72,
		"inventory_pool": "military",
		"special_deal_chance": 0.2,
	},
	TraderType.SCIENTIST: {
		"name": "Research Vendor",
		"description": "Scientific equipment and research materials.",
		"buy_modifier": 1.2,
		"sell_modifier": 0.5,
		"currency": CurrencyType.RESEARCH_CREDITS,
		"restock_hours": 48,
		"inventory_pool": "research",
		"special_deal_chance": 0.15,
	},
}


# ============================================================================
# ITEM POOLS
# ============================================================================

const INVENTORY_POOLS := {
	"general": {
		"items": [
			{"item_id": "water_bottle", "base_price": 10, "rarity": ItemRarity.COMMON, "stock_range": [5, 15]},
			{"item_id": "canned_food", "base_price": 15, "rarity": ItemRarity.COMMON, "stock_range": [3, 10]},
			{"item_id": "bandage", "base_price": 20, "rarity": ItemRarity.COMMON, "stock_range": [5, 12]},
			{"item_id": "flashlight", "base_price": 35, "rarity": ItemRarity.COMMON, "stock_range": [2, 5]},
			{"item_id": "rope", "base_price": 25, "rarity": ItemRarity.COMMON, "stock_range": [3, 8]},
			{"item_id": "backpack_small", "base_price": 100, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
			{"item_id": "matches", "base_price": 5, "rarity": ItemRarity.COMMON, "stock_range": [10, 25]},
			{"item_id": "duct_tape", "base_price": 15, "rarity": ItemRarity.COMMON, "stock_range": [5, 15]},
		],
	},
	"weapons": {
		"items": [
			{"item_id": "pistol", "base_price": 200, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
			{"item_id": "shotgun", "base_price": 350, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 2]},
			{"item_id": "rifle", "base_price": 450, "rarity": ItemRarity.RARE, "stock_range": [0, 2]},
			{"item_id": "pistol_ammo", "base_price": 5, "rarity": ItemRarity.COMMON, "stock_range": [20, 50]},
			{"item_id": "shotgun_ammo", "base_price": 8, "rarity": ItemRarity.COMMON, "stock_range": [10, 30]},
			{"item_id": "rifle_ammo", "base_price": 10, "rarity": ItemRarity.UNCOMMON, "stock_range": [10, 25]},
			{"item_id": "knife", "base_price": 50, "rarity": ItemRarity.COMMON, "stock_range": [2, 5]},
			{"item_id": "machete", "base_price": 80, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
			{"item_id": "armor_vest", "base_price": 300, "rarity": ItemRarity.RARE, "stock_range": [0, 2]},
		],
	},
	"medical": {
		"items": [
			{"item_id": "bandage", "base_price": 15, "rarity": ItemRarity.COMMON, "stock_range": [10, 25]},
			{"item_id": "medkit", "base_price": 75, "rarity": ItemRarity.UNCOMMON, "stock_range": [2, 6]},
			{"item_id": "painkillers", "base_price": 30, "rarity": ItemRarity.COMMON, "stock_range": [5, 15]},
			{"item_id": "antibiotics", "base_price": 100, "rarity": ItemRarity.RARE, "stock_range": [1, 5]},
			{"item_id": "antidote", "base_price": 150, "rarity": ItemRarity.RARE, "stock_range": [1, 3]},
			{"item_id": "splint", "base_price": 40, "rarity": ItemRarity.UNCOMMON, "stock_range": [2, 6]},
			{"item_id": "surgical_kit", "base_price": 250, "rarity": ItemRarity.EPIC, "stock_range": [0, 2]},
		],
	},
	"vehicle_parts": {
		"items": [
			{"item_id": "gasoline_canister", "base_price": 50, "rarity": ItemRarity.COMMON, "stock_range": [3, 8]},
			{"item_id": "engine_parts", "base_price": 150, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 4]},
			{"item_id": "tire", "base_price": 80, "rarity": ItemRarity.COMMON, "stock_range": [2, 6]},
			{"item_id": "battery", "base_price": 120, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
			{"item_id": "spark_plugs", "base_price": 30, "rarity": ItemRarity.COMMON, "stock_range": [4, 10]},
			{"item_id": "brake_pads", "base_price": 60, "rarity": ItemRarity.UNCOMMON, "stock_range": [2, 5]},
			{"item_id": "transmission_fluid", "base_price": 40, "rarity": ItemRarity.COMMON, "stock_range": [3, 8]},
		],
	},
	"black_market": {
		"items": [
			{"item_id": "assault_rifle", "base_price": 800, "rarity": ItemRarity.RARE, "stock_range": [0, 2]},
			{"item_id": "sniper_rifle", "base_price": 1000, "rarity": ItemRarity.EPIC, "stock_range": [0, 1]},
			{"item_id": "explosives", "base_price": 500, "rarity": ItemRarity.RARE, "stock_range": [1, 3]},
			{"item_id": "night_vision", "base_price": 600, "rarity": ItemRarity.RARE, "stock_range": [0, 2]},
			{"item_id": "silencer", "base_price": 350, "rarity": ItemRarity.RARE, "stock_range": [0, 3]},
			{"item_id": "military_armor", "base_price": 750, "rarity": ItemRarity.EPIC, "stock_range": [0, 1]},
			{"item_id": "rare_blueprint", "base_price": 1500, "rarity": ItemRarity.LEGENDARY, "stock_range": [0, 1]},
		],
	},
	"farm": {
		"items": [
			{"item_id": "vegetables", "base_price": 8, "rarity": ItemRarity.COMMON, "stock_range": [10, 30]},
			{"item_id": "fruit", "base_price": 10, "rarity": ItemRarity.COMMON, "stock_range": [8, 25]},
			{"item_id": "meat_raw", "base_price": 15, "rarity": ItemRarity.COMMON, "stock_range": [5, 15]},
			{"item_id": "seeds", "base_price": 5, "rarity": ItemRarity.COMMON, "stock_range": [15, 40]},
			{"item_id": "fertilizer", "base_price": 20, "rarity": ItemRarity.UNCOMMON, "stock_range": [5, 15]},
			{"item_id": "water_purifier", "base_price": 100, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
		],
	},
	"crafting": {
		"items": [
			{"item_id": "wood_planks", "base_price": 5, "rarity": ItemRarity.COMMON, "stock_range": [20, 50]},
			{"item_id": "nails", "base_price": 3, "rarity": ItemRarity.COMMON, "stock_range": [30, 80]},
			{"item_id": "metal_scrap", "base_price": 8, "rarity": ItemRarity.COMMON, "stock_range": [15, 40]},
			{"item_id": "cloth", "base_price": 6, "rarity": ItemRarity.COMMON, "stock_range": [15, 35]},
			{"item_id": "leather", "base_price": 15, "rarity": ItemRarity.UNCOMMON, "stock_range": [5, 15]},
			{"item_id": "electronics", "base_price": 50, "rarity": ItemRarity.UNCOMMON, "stock_range": [2, 8]},
			{"item_id": "blueprint_common", "base_price": 100, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
		],
	},
	"military": {
		"items": [
			{"item_id": "military_rifle", "base_price": 600, "rarity": ItemRarity.RARE, "stock_range": [0, 2]},
			{"item_id": "military_helmet", "base_price": 200, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
			{"item_id": "military_boots", "base_price": 150, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 4]},
			{"item_id": "military_rations", "base_price": 30, "rarity": ItemRarity.COMMON, "stock_range": [5, 15]},
			{"item_id": "grenade", "base_price": 150, "rarity": ItemRarity.RARE, "stock_range": [0, 5]},
			{"item_id": "tactical_vest", "base_price": 400, "rarity": ItemRarity.RARE, "stock_range": [0, 2]},
			{"item_id": "binoculars", "base_price": 80, "rarity": ItemRarity.UNCOMMON, "stock_range": [1, 3]},
		],
	},
	"research": {
		"items": [
			{"item_id": "sample_container", "base_price": 50, "rarity": ItemRarity.UNCOMMON, "stock_range": [3, 8]},
			{"item_id": "research_data", "base_price": 200, "rarity": ItemRarity.RARE, "stock_range": [1, 3]},
			{"item_id": "experimental_serum", "base_price": 500, "rarity": ItemRarity.EPIC, "stock_range": [0, 2]},
			{"item_id": "lab_equipment", "base_price": 150, "rarity": ItemRarity.UNCOMMON, "stock_range": [2, 5]},
			{"item_id": "chemical_compounds", "base_price": 75, "rarity": ItemRarity.UNCOMMON, "stock_range": [3, 10]},
		],
	},
	"rare_goods": {
		"items": [
			{"item_id": "legendary_weapon", "base_price": 2000, "rarity": ItemRarity.LEGENDARY, "stock_range": [0, 1]},
			{"item_id": "rare_artifact", "base_price": 1500, "rarity": ItemRarity.EPIC, "stock_range": [0, 1]},
			{"item_id": "unique_blueprint", "base_price": 3000, "rarity": ItemRarity.LEGENDARY, "stock_range": [0, 1]},
			{"item_id": "exotic_material", "base_price": 750, "rarity": ItemRarity.RARE, "stock_range": [0, 3]},
			{"item_id": "collectors_item", "base_price": 1000, "rarity": ItemRarity.EPIC, "stock_range": [0, 2]},
		],
	},
}


# ============================================================================
# STATE
# ============================================================================

var _player_currencies: Dictionary = {
	CurrencyType.COINS: 100,
	CurrencyType.TRADE_NOTES: 0,
	CurrencyType.MILITARY_SCRIP: 0,
	CurrencyType.RESEARCH_CREDITS: 0,
}

var _traders: Dictionary = {}  # trader_id -> trader data
var _active_trade: Dictionary = {}  # Current trade session
var _special_deals: Dictionary = {}  # trader_id -> [deal1, deal2...]
var _trader_id_counter: int = 0
var _game_hours: float = 0.0  # For restock timing


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_game_hours += delta / 3600.0  # Convert seconds to hours
	_check_restocks()


# ============================================================================
# TRADER MANAGEMENT
# ============================================================================

func create_trader(trader_type: int, npc_id: String = "") -> Dictionary:
	var definition: Dictionary = TRADER_DEFINITIONS.get(trader_type, {})
	if definition.is_empty():
		return {"success": false, "error": "Unknown trader type"}
	
	_trader_id_counter += 1
	var trader_id: String = npc_id if npc_id != "" else "trader_%d" % _trader_id_counter
	
	var trader_data := {
		"id": trader_id,
		"type": trader_type,
		"type_name": TraderType.keys()[trader_type],
		"name": definition.get("name", "Trader"),
		"description": definition.get("description", ""),
		
		# Trading modifiers
		"buy_modifier": definition.get("buy_modifier", 1.0),
		"sell_modifier": definition.get("sell_modifier", 0.5),
		"currency": definition.get("currency", CurrencyType.COINS),
		
		# Inventory
		"inventory_pool": definition.get("inventory_pool", "general"),
		"inventory": [],
		
		# Restocking
		"restock_hours": definition.get("restock_hours", 24),
		"last_restock": _game_hours,
		
		# Special deals
		"special_deal_chance": definition.get("special_deal_chance", 0.1),
		
		# Stats
		"total_trades": 0,
		"total_value": 0,
	}
	
	# Generate initial inventory
	_restock_trader(trader_data)
	
	_traders[trader_id] = trader_data
	
	return {"success": true, "trader_id": trader_id, "trader": trader_data}


func _restock_trader(trader: Dictionary) -> void:
	var pool_name: String = trader.get("inventory_pool", "general")
	var pool: Dictionary = INVENTORY_POOLS.get(pool_name, {})
	var items: Array = pool.get("items", [])
	
	trader["inventory"] = []
	
	for item_def in items:
		var stock_range: Array = item_def.get("stock_range", [1, 5])
		var min_stock: int = stock_range[0]
		var max_stock: int = stock_range[1]
		var stock: int = randi_range(min_stock, max_stock)
		
		if stock > 0:
			trader["inventory"].append({
				"item_id": item_def["item_id"],
				"base_price": item_def["base_price"],
				"rarity": item_def["rarity"],
				"quantity": stock,
				"max_quantity": max_stock,
			})
	
	trader["last_restock"] = _game_hours
	
	# Generate special deals
	_generate_special_deals(trader)
	
	emit_signal("trader_restocked", trader["id"])


func _generate_special_deals(trader: Dictionary) -> void:
	var deal_chance: float = trader.get("special_deal_chance", 0.1)
	var trader_id: String = trader["id"]
	
	_special_deals[trader_id] = []
	
	for item in trader.get("inventory", []):
		if randf() < deal_chance:
			var discount: float = randf_range(0.1, 0.3)  # 10-30% off
			var deal := {
				"item_id": item["item_id"],
				"original_price": item["base_price"],
				"discount": discount,
				"discounted_price": int(item["base_price"] * (1.0 - discount)),
				"expires_hours": _game_hours + randf_range(2.0, 12.0),
			}
			_special_deals[trader_id].append(deal)
			emit_signal("special_deal_available", trader_id, deal)


func _check_restocks() -> void:
	for trader_id in _traders:
		var trader: Dictionary = _traders[trader_id]
		var hours_since_restock: float = _game_hours - trader.get("last_restock", 0.0)
		
		if hours_since_restock >= trader.get("restock_hours", 24):
			_restock_trader(trader)


# ============================================================================
# TRADING SESSION
# ============================================================================

func start_trade(trader_id: String, faction_discount: float = 0.0) -> Dictionary:
	if trader_id not in _traders:
		return {"success": false, "error": "Trader not found"}
	
	var trader: Dictionary = _traders[trader_id]
	
	_active_trade = {
		"trader_id": trader_id,
		"trader": trader,
		"cart": [],  # Items to buy
		"sell_cart": [],  # Items to sell
		"faction_discount": faction_discount,
		"total_cost": 0,
		"total_value": 0,
	}
	
	emit_signal("trade_started", trader_id, trader.get("type"))
	
	return {
		"success": true,
		"trader": trader,
		"inventory": trader.get("inventory", []),
		"special_deals": _special_deals.get(trader_id, []),
		"currency": trader.get("currency"),
		"player_currency": _player_currencies.get(trader.get("currency"), 0),
	}


func add_to_cart(item_id: String, quantity: int = 1) -> Dictionary:
	if _active_trade.is_empty():
		return {"success": false, "error": "No active trade"}
	
	var trader: Dictionary = _active_trade["trader"]
	var inventory: Array = trader.get("inventory", [])
	
	# Find item in trader inventory
	var item_data: Dictionary = {}
	for item in inventory:
		if item["item_id"] == item_id:
			item_data = item
			break
	
	if item_data.is_empty():
		return {"success": false, "error": "Item not in stock"}
	
	if item_data["quantity"] < quantity:
		return {"success": false, "error": "Insufficient stock"}
	
	# Calculate price
	var base_price: int = item_data["base_price"]
	var buy_modifier: float = trader.get("buy_modifier", 1.0)
	var faction_discount: float = _active_trade.get("faction_discount", 0.0)
	var unit_price: int = int(base_price * buy_modifier * (1.0 - faction_discount))
	var total_price: int = unit_price * quantity
	
	# Check for special deal
	var deals: Array = _special_deals.get(trader.get("id", ""), [])
	for deal in deals:
		if deal["item_id"] == item_id and deal.get("expires_hours", 0) > _game_hours:
			unit_price = int(deal["discounted_price"] * (1.0 - faction_discount))
			total_price = unit_price * quantity
			break
	
	# Add to cart
	var cart: Array = _active_trade["cart"]
	var found := false
	for cart_item in cart:
		if cart_item["item_id"] == item_id:
			cart_item["quantity"] += quantity
			cart_item["total_price"] += total_price
			found = true
			break
	
	if not found:
		cart.append({
			"item_id": item_id,
			"quantity": quantity,
			"unit_price": unit_price,
			"total_price": total_price,
		})
	
	# Update total
	_active_trade["total_cost"] += total_price
	
	return {"success": true, "cart": cart, "total_cost": _active_trade["total_cost"]}


func remove_from_cart(item_id: String, quantity: int = 1) -> Dictionary:
	if _active_trade.is_empty():
		return {"success": false, "error": "No active trade"}
	
	var cart: Array = _active_trade["cart"]
	
	for i in range(cart.size() - 1, -1, -1):
		var cart_item: Dictionary = cart[i]
		if cart_item["item_id"] == item_id:
			var remove_qty: int = mini(quantity, cart_item["quantity"])
			var remove_cost: int = cart_item["unit_price"] * remove_qty
			
			cart_item["quantity"] -= remove_qty
			cart_item["total_price"] -= remove_cost
			_active_trade["total_cost"] -= remove_cost
			
			if cart_item["quantity"] <= 0:
				cart.remove_at(i)
			
			return {"success": true, "cart": cart, "total_cost": _active_trade["total_cost"]}
	
	return {"success": false, "error": "Item not in cart"}


func add_to_sell_cart(item_id: String, quantity: int = 1) -> Dictionary:
	if _active_trade.is_empty():
		return {"success": false, "error": "No active trade"}
	
	# Would check player inventory here
	
	var trader: Dictionary = _active_trade["trader"]
	var sell_modifier: float = trader.get("sell_modifier", 0.5)
	
	# Get item base price (would lookup from ItemDatabase)
	var base_price: int = _get_item_base_price(item_id)
	var unit_price: int = int(base_price * sell_modifier)
	var total_price: int = unit_price * quantity
	
	# Add to sell cart
	var sell_cart: Array = _active_trade["sell_cart"]
	var found := false
	for cart_item in sell_cart:
		if cart_item["item_id"] == item_id:
			cart_item["quantity"] += quantity
			cart_item["total_price"] += total_price
			found = true
			break
	
	if not found:
		sell_cart.append({
			"item_id": item_id,
			"quantity": quantity,
			"unit_price": unit_price,
			"total_price": total_price,
		})
	
	_active_trade["total_value"] += total_price
	
	return {"success": true, "sell_cart": sell_cart, "total_value": _active_trade["total_value"]}


func _get_item_base_price(item_id: String) -> int:
	# Lookup in all pools
	for pool_name in INVENTORY_POOLS:
		var pool: Dictionary = INVENTORY_POOLS[pool_name]
		for item in pool.get("items", []):
			if item["item_id"] == item_id:
				return item["base_price"]
	return 10  # Default


func complete_trade() -> Dictionary:
	if _active_trade.is_empty():
		return {"success": false, "error": "No active trade"}
	
	var trader: Dictionary = _active_trade["trader"]
	var cart: Array = _active_trade["cart"]
	var sell_cart: Array = _active_trade["sell_cart"]
	var total_cost: int = _active_trade["total_cost"]
	var total_value: int = _active_trade["total_value"]
	var currency: int = trader.get("currency", CurrencyType.COINS)
	var player_currency: int = _player_currencies.get(currency, 0)
	
	# Net cost (cost - value of items sold)
	var net_cost: int = total_cost - total_value
	
	if net_cost > player_currency:
		return {"success": false, "error": "Insufficient funds"}
	
	# Process purchases
	var trader_inventory: Array = trader.get("inventory", [])
	var purchased_items: Array = []
	
	for cart_item in cart:
		for inv_item in trader_inventory:
			if inv_item["item_id"] == cart_item["item_id"]:
				inv_item["quantity"] -= cart_item["quantity"]
				break
		
		purchased_items.append({
			"item_id": cart_item["item_id"],
			"quantity": cart_item["quantity"],
		})
		
		emit_signal("item_purchased", cart_item["item_id"], cart_item["quantity"], cart_item["total_price"])
	
	# Process sales
	var sold_items: Array = []
	for cart_item in sell_cart:
		sold_items.append({
			"item_id": cart_item["item_id"],
			"quantity": cart_item["quantity"],
		})
		
		emit_signal("item_sold", cart_item["item_id"], cart_item["quantity"], cart_item["total_price"])
	
	# Update currency
	var old_currency: int = player_currency
	_player_currencies[currency] = player_currency - net_cost
	emit_signal("currency_changed", old_currency, _player_currencies[currency])
	
	# Update trader stats
	trader["total_trades"] += 1
	trader["total_value"] += total_cost
	
	var trader_id: String = trader.get("id", "")
	emit_signal("trade_completed", trader_id, total_cost)
	
	# Clear active trade
	var result := {
		"success": true,
		"purchased": purchased_items,
		"sold": sold_items,
		"total_spent": total_cost,
		"total_earned": total_value,
		"net_cost": net_cost,
	}
	
	_active_trade = {}
	
	return result


func cancel_trade() -> void:
	if _active_trade.is_empty():
		return
	
	var trader_id: String = _active_trade.get("trader", {}).get("id", "")
	_active_trade = {}
	
	emit_signal("trade_cancelled", trader_id)


# ============================================================================
# HAGGLING
# ============================================================================

func attempt_haggle(item_id: String) -> Dictionary:
	if _active_trade.is_empty():
		return {"success": false, "error": "No active trade"}
	
	# Haggling mini-game logic
	var base_success_chance := 0.3
	
	# Could be modified by player skills/perks
	var success := randf() < base_success_chance
	
	if success:
		var discount: float = randf_range(0.05, 0.15)  # 5-15% discount
		
		# Update cart item if present
		var cart: Array = _active_trade["cart"]
		for cart_item in cart:
			if cart_item["item_id"] == item_id:
				var old_price: int = cart_item["total_price"]
				var new_price: int = int(old_price * (1.0 - discount))
				var savings: int = old_price - new_price
				
				cart_item["total_price"] = new_price
				_active_trade["total_cost"] -= savings
				
				emit_signal("haggle_success", item_id, discount)
				return {"success": true, "discount": discount, "savings": savings}
		
		emit_signal("haggle_success", item_id, discount)
		return {"success": true, "discount": discount}
	else:
		emit_signal("haggle_failed", item_id)
		return {"success": false, "error": "Haggle failed"}


# ============================================================================
# CURRENCY MANAGEMENT
# ============================================================================

func add_currency(currency_type: int, amount: int) -> void:
	var old_amount: int = _player_currencies.get(currency_type, 0)
	_player_currencies[currency_type] = old_amount + amount
	emit_signal("currency_changed", old_amount, _player_currencies[currency_type])


func remove_currency(currency_type: int, amount: int) -> bool:
	var current: int = _player_currencies.get(currency_type, 0)
	if current < amount:
		return false
	
	_player_currencies[currency_type] = current - amount
	emit_signal("currency_changed", current, _player_currencies[currency_type])
	return true


func get_currency(currency_type: int) -> int:
	return _player_currencies.get(currency_type, 0)


func get_currency_name(currency_type: int) -> String:
	match currency_type:
		CurrencyType.COINS:
			return "Coins"
		CurrencyType.TRADE_NOTES:
			return "Trade Notes"
		CurrencyType.MILITARY_SCRIP:
			return "Military Scrip"
		CurrencyType.RESEARCH_CREDITS:
			return "Research Credits"
		_:
			return "Unknown"


# ============================================================================
# QUERIES
# ============================================================================

func get_trader(trader_id: String) -> Dictionary:
	return _traders.get(trader_id, {})


func get_all_traders() -> Array:
	return _traders.values()


func get_traders_by_type(trader_type: int) -> Array:
	var traders: Array = []
	for trader in _traders.values():
		if trader.get("type") == trader_type:
			traders.append(trader)
	return traders


func get_special_deals(trader_id: String) -> Array:
	var deals: Array = _special_deals.get(trader_id, [])
	var valid_deals: Array = []
	
	for deal in deals:
		if deal.get("expires_hours", 0) > _game_hours:
			valid_deals.append(deal)
	
	return valid_deals


func get_item_buy_price(trader_id: String, item_id: String) -> int:
	var trader: Dictionary = _traders.get(trader_id, {})
	if trader.is_empty():
		return -1
	
	var buy_modifier: float = trader.get("buy_modifier", 1.0)
	
	for item in trader.get("inventory", []):
		if item["item_id"] == item_id:
			return int(item["base_price"] * buy_modifier)
	
	return -1


func get_item_sell_price(trader_id: String, item_id: String) -> int:
	var trader: Dictionary = _traders.get(trader_id, {})
	if trader.is_empty():
		return -1
	
	var sell_modifier: float = trader.get("sell_modifier", 0.5)
	var base_price: int = _get_item_base_price(item_id)
	
	return int(base_price * sell_modifier)


func is_trade_active() -> bool:
	return not _active_trade.is_empty()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	return {
		"player_currencies": _player_currencies.duplicate(),
		"traders": _traders.duplicate(true),
		"special_deals": _special_deals.duplicate(true),
		"trader_id_counter": _trader_id_counter,
		"game_hours": _game_hours,
	}


func load_data(data: Dictionary) -> void:
	_player_currencies = data.get("player_currencies", {
		CurrencyType.COINS: 100,
		CurrencyType.TRADE_NOTES: 0,
		CurrencyType.MILITARY_SCRIP: 0,
		CurrencyType.RESEARCH_CREDITS: 0,
	})
	_traders = data.get("traders", {})
	_special_deals = data.get("special_deals", {})
	_trader_id_counter = data.get("trader_id_counter", 0)
	_game_hours = data.get("game_hours", 0.0)
