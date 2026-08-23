module MoreWeaponFilters

enum ExtraFilterButtonsPosition {
	Above = 0,
	Inline = 1,
	Below = 2
}

class MoreWeaponFiltersConfig extends ScriptableSystem {
	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Button Positions")
	@runtimeProperty("ModSettings.category.order", "1")
	@runtimeProperty("ModSettings.displayName", "Move Weapon Equip Sorting Button Down")
	@runtimeProperty("ModSettings.description", "Move sorting button down a row in the weapon equip screen.")
	public let moveSortButtonDown: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Button Positions")
	@runtimeProperty("ModSettings.category.order", "1")
	@runtimeProperty("ModSettings.displayName", "Move Backpack Sorting Button Down")
	@runtimeProperty("ModSettings.description", "Move sorting button down a row in the backpack screen. When disabled, decreases the dropdown button width a bit to avoid overlapping. Note: this should be disabled if using the backpack search mod.")
	public let moveBackpackSortButtonDown: Bool = false;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Button Positions")
	@runtimeProperty("ModSettings.category.order", "1")
	@runtimeProperty("ModSettings.displayName", "Move Weapon Equip Filter Buttons Up")
	@runtimeProperty("ModSettings.description", "Move filter buttons up a row in the weapon selection screen. Does not apply to the backpack screen.")
	public let moveFilterButtonsUp: Bool = false;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Button Positions")
	@runtimeProperty("ModSettings.category.order", "1")
	@runtimeProperty("ModSettings.displayName", "Extra Filter Buttons Position")
	@runtimeProperty("ModSettings.description", "Where the new filter buttons are placed on the weapon selection screen, relative to the default filter buttons. Does not apply to the backpack screen.")
	@runtimeProperty("ModSettings.displayValues", "\"Above\", \"Inline\", \"Below\"")
	public let extraFilterPosition: ExtraFilterButtonsPosition = ExtraFilterButtonsPosition.Inline;

	// Ranged Toggles

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Ranged Toggles")
	@runtimeProperty("ModSettings.category.order", "2")
	@runtimeProperty("ModSettings.displayName", "Weapon Equip Menu: Add ranged filters")
	public let enableRangedEquipFilters: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Ranged Toggles")
	@runtimeProperty("ModSettings.category.order", "2")
	@runtimeProperty("ModSettings.displayName", "Backpack menu: Add ranged filters")
	public let enableRangedBackpackFilters: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Ranged Toggles")
	@runtimeProperty("ModSettings.category.order", "2")
	@runtimeProperty("ModSettings.displayName", "Stash and vendor menus: Add ranged filters")
	public let enableRangedVendorFilters: Bool = true;

	// Melee Toggles

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Melee Toggles")
	@runtimeProperty("ModSettings.category.order", "3")
	@runtimeProperty("ModSettings.displayName", "Weapon Equip Menu: Add melee filters")
	public let enableMeleeEquipFilters: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Melee Toggles")
	@runtimeProperty("ModSettings.category.order", "3")
	@runtimeProperty("ModSettings.displayName", "Backpack menu: Add melee filters")
	public let enableMeleeBackpackFilters: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Melee Toggles")
	@runtimeProperty("ModSettings.category.order", "3")
	@runtimeProperty("ModSettings.displayName", "Stash and vendor menus: Add melee filters")
	public let enableMeleeVendorFilters: Bool = true;

	// Item Toggles

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Item Toggles")
	@runtimeProperty("ModSettings.category.order", "4")
	@runtimeProperty("ModSettings.displayName", "Backpack menu: Add item filters")
	public let enableItemBackpackFilters: Bool = false;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Item Toggles")
	@runtimeProperty("ModSettings.category.order", "4")
	@runtimeProperty("ModSettings.displayName", "Stash and vendor menus: Add item filters")
	public let enableItemVendorFilters: Bool = false;

	// Misc

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.category", "Misc")
	@runtimeProperty("ModSettings.category.order", "5")
	@runtimeProperty("ModSettings.displayName", "Keep Selected Filter on Equip/Unequip")
	@runtimeProperty("ModSettings.description", "When you equip or unequip a weapon, keep the currently selected filter instead of changing to the generic ranged/melee weapon filter.")
	public let keepFilterSelectOnEquip: Bool = true;

	/* Mod Settings helpers & listeners */

	public static func Get(gi: GameInstance) -> ref<MoreWeaponFiltersConfig> {
		return GameInstance.GetScriptableSystemsContainer(gi).Get(n"MoreWeaponFilters.MoreWeaponFiltersConfig") as MoreWeaponFiltersConfig;
	}

	@if(ModuleExists("ModSettingsModule"))
	private func OnAttach() -> Void { ModSettings.RegisterListenerToClass(this); }

	@if(ModuleExists("ModSettingsModule"))
	private func OnDetach() -> Void { ModSettings.RegisterListenerToClass(this); }
}
