module MoreWeaponFilters

enum ExtraFilterButtonsPosition {
	Above = 0,
	Inline = 1,
	Below = 2
}

class MoreWeaponFiltersConfig extends ScriptableSystem {
	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.displayName", "Move Weapon Equip Sorting Button Down")
	@runtimeProperty("ModSettings.description", "Move sorting button down a row in the weapon equip screen.")
	public let moveSortButtonDown: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.displayName", "Move Backpack Sorting Button Down")
	@runtimeProperty("ModSettings.description", "Move sorting button down a row in the backpack screen. When disabled, decreases the dropdown button width a bit to avoid overlapping. Note: this should be disabled if using the backpack search mod.")
	public let moveBackpackSortButtonDown: Bool = false;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.displayName", "Move Weapon Equip Filter Buttons Up")
	@runtimeProperty("ModSettings.description", "Move filter buttons up a row in the weapon selection screen. Does not apply to the backpack screen.")
	public let moveFilterButtonsUp: Bool = false;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.displayName", "Extra Filter Buttons Position")
	@runtimeProperty("ModSettings.description", "Where the new filter buttons are placed on the weapon selection screen, relative to the default filter buttons. Does not apply to the backpack screen.")
	@runtimeProperty("ModSettings.displayValues", "\"Above\", \"Inline\", \"Below\"")
	public let extraFilterPosition: ExtraFilterButtonsPosition = ExtraFilterButtonsPosition.Inline;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.displayName", "Add filters to stash and vendor menus")
	public let enableVendorFilters: Bool = true;

	@runtimeProperty("ModSettings.mod", "More Weapon Filters")
	@runtimeProperty("ModSettings.displayName", "Keep Selected Filter on Equip/Unequip")
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
