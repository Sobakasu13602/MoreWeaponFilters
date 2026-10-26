module MoreWeaponFilters

// Extended filter categories for ItemFilterCategory enum
enum ItemFilterCategory2 {
	// Values from ItemFilterCategory for ease of use
	Invalid = -1,
	RangedWeapons = 0,
	MeleeWeapons = 1,
	Clothes = 2,
	Consumables = 3,
	Grenades = 4,
	SoftwareMods = 5,
	Attachments = 6,
	Programs = 7,
	Cyberware = 8,
	Junk = 9,
	Quest = 11,
	NewWardrobeAppearances = 12,
	Buyback = 13,

	Handgun = 20,
	Automatic = 21,
	LongRange = 22,
	Shotgun = 23,
	OtherRanged = 24,

	Thrown = 25,
	Blade = 26,
	Blunt = 27,
	OtherMelee = 28,

	Iconic = 29,			// Iconic items
	CraftingPart = 30,		// Crafting and quickhack components
	CraftingRecipe = 31,	// Crafting and quickhack recepies (These don't actually appear in your backpack)
	Uncategorized = 32,		// Anything else
	AllCount = 33,

	// These are separate filters that AND with the normal filters (e.g. Handgun + Power)
	WeaponClassAll = 40,
	WeaponClassIconic = 41,
	WeaponClassPower = 42,
	WeaponClassTech = 43,
	WeaponClassSmart = 44,
	WeaponClassCount = 45,
}

// Refactor PopulateInventory, change local tagsToFilterOut variable into m_tagsToFilterOut field.
@addField(BackpackMainGameController)
private let m_tagsToFilterOut: array<CName>;

// Additional filters are controlled by the m_additionalFilters field.
@addField(BackpackMainGameController)
private let m_additionalFilters: array<ItemFilterCategory2>;

@addField(BackpackMainGameController)
private let modSortButtonWidthSet: Bool = false;
@addField(BackpackMainGameController)
private let modSortButtonWidth: Float;
@addField(BackpackMainGameController)
private let modSortButtonReparented: Bool = false;

// Set inventory blacklist (quickhacks are no longer on it), and additional filters
@wrapMethod(BackpackMainGameController)
protected cb func OnInitialize() -> Bool {
	let moreWeaponFiltersConfig = MoreWeaponFiltersConfig.Get(GetGameInstance());

	ArrayPush(this.m_tagsToFilterOut, n"HideInBackpackUI");

	if moreWeaponFiltersConfig.enableRangedBackpackFilters {
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Handgun);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Automatic);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.LongRange);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Shotgun);
	}

	if moreWeaponFiltersConfig.enableMeleeBackpackFilters {
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Thrown);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Blade);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Blunt);
	}

	if moreWeaponFiltersConfig.enableItemBackpackFilters {
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Iconic);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Quest);
		ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Uncategorized);
	}

	let result = wrappedMethod();

	// Shift sorting button/dropdown down in the backpack menu. There's too many
	// filters now, which would cause them to extend underneath the sorting button
	let moreWeaponFiltersConfig = MoreWeaponFiltersConfig.Get(GetGameInstance());
	if moreWeaponFiltersConfig.moveBackpackSortButtonDown {
		let root = this.GetRootCompoundWidget();
		let container = root.GetWidgetByPathName(n"wrapper/inkCanvasWidget21/inkVerticalPanelWidget25") as inkCompoundWidget;
		if !this.modSortButtonReparented {
			// Move the dropdown button into its parent. By default it's inside the same
			// horizontal widget as the filter buttons, which prevented SetTranslation
			// from working when I tried that in the past
			inkWidgetRef.Reparent(this.m_sortingButton, container);
			this.modSortButtonReparented = true;
		}
		inkWidgetRef.SetPadding(this.m_sortingDropdown, 0.0, 82.0, 0.0, 0.0);
	} else {
		if !this.modSortButtonWidthSet {
			this.modSortButtonWidth = inkWidgetRef.GetWidth(this.m_sortingButton) * 0.8;
			this.modSortButtonWidthSet = true;
		}
		inkWidgetRef.SetWidth(this.m_sortingButton, this.modSortButtonWidth);
		inkWidgetRef.SetPadding(this.m_sortingDropdown, 85.5, 0.0, 0.0, 0.0);
	}

	return result;
}

// Backpack Search compatibility: only add the extra margin if it's not present.
// Otherwise the margin added by this will push the dropdown even further down since
// that also has an 8.0 top margin. This is in `OnPlayerAttach` instead of
// `OnInitialize` since that's where Backpack Search creates the `searchContainer`.
// Doing the check in `OnInitialize` would probably run into issues depending on which
// wrapper runs first.
@wrapMethod(BackpackMainGameController)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
	let result = wrappedMethod(playerPuppet);

	let root = this.GetRootCompoundWidget();
	let container = root.GetWidgetByPathName(n"wrapper/inkCanvasWidget21/inkVerticalPanelWidget25") as inkCompoundWidget;

	if !IsDefined(container.GetWidgetByPathName(n"searchContainer")) {
		inkWidgetRef.SetMargin(this.m_sortingButton, 0.0, 8.0, 0.0, 0.0);
	}
	return result;
}


// Refactor PopulateInventory, use m_tagsToFilterOut and m_additionalFilters to manage filtering
@replaceMethod(BackpackMainGameController)
private final func PopulateInventory() -> Void {
	let dropItem: ItemModParams;
	let i: Int32;
	let limit: Int32;
	let playerItems: ref<inkHashMap>;
	let quantity: Int32;
	let tagsToFilterOut: array<CName>;
	let uiInventoryItem: ref<UIInventoryItem>;
	let values: array<wref<IScriptable>>;
	let wrappedItem: ref<WrappedInventoryItemData>;
	let wrappedItems: array<ref<IScriptable>>;
	let filterManager: ref<ItemCategoryFliterManager> = ItemCategoryFliterManager.Make();
	//filterManager.AddFilterToCheck(ItemFilterCategory.Quest);
	//ArrayPush(tagsToFilterOut, n"HideInBackpackUI");
	//ArrayPush(tagsToFilterOut, n"SoftwareShard");
	this.m_uiInventorySystem.FlushTempData();
	playerItems = this.m_uiInventorySystem.GetPlayerItemsMap();
	playerItems.GetValues(values);
	ArrayClear(this.m_junkItems);
	i = 0;
	limit = ArraySize(values);
	while i < limit {
		uiInventoryItem = values[i] as UIInventoryItem;
		if !ItemID.HasFlag(uiInventoryItem.GetID(), gameEItemIDFlag.Preview) && !uiInventoryItem.HasAnyTag(this.m_tagsToFilterOut) {
			if ArrayContains(this.m_itemDropQueueItems, uiInventoryItem.ID) {
				quantity = uiInventoryItem.GetQuantity(true);
				dropItem = this.GetDropQueueItem(uiInventoryItem.ID);
				if dropItem.quantity >= quantity {
				} else {
					uiInventoryItem.SetQuantity(quantity - dropItem.quantity);
					if uiInventoryItem.IsJunk() {
						ArrayPush(this.m_junkItems, uiInventoryItem);
					};
					wrappedItem = new WrappedInventoryItemData();
					wrappedItem.DisplayContextData = this.m_itemDisplayContext;
					wrappedItem.IsNew = uiInventoryItem.IsNew();
					wrappedItem.IsPlayerFavourite = uiInventoryItem.IsPlayerFavourite();
					wrappedItem.Item = uiInventoryItem;
					wrappedItem.NotificationListener = this.m_immediateNotificationListener;
					filterManager.AddItem(uiInventoryItem.GetFilterCategory());
					ArrayPush(wrappedItems, wrappedItem);
				};
			} else {
				// NOTE: In the original function this else block isn't here, and this code would be
				// ran for items in the drop queue as well. That doesn't make any sense sense though,
				// because it's adding items that are being dropped to be displayed in the inventory.
				// As a test, I made a "mod" which only copy/pastes the original function and disabled
				// this mod. Doing so has the same issue where items don't appear to be dropped. So it
				// seems like there may be something wrong with that original function, and this
				// really is supposed to be in an else block like it is here.

				if uiInventoryItem.IsJunk() {
					ArrayPush(this.m_junkItems, uiInventoryItem);
				};
				wrappedItem = new WrappedInventoryItemData();
				wrappedItem.DisplayContextData = this.m_itemDisplayContext;
				wrappedItem.IsNew = uiInventoryItem.IsNew();
				wrappedItem.IsPlayerFavourite = uiInventoryItem.IsPlayerFavourite();
				wrappedItem.Item = uiInventoryItem;
				wrappedItem.NotificationListener = this.m_immediateNotificationListener;
				filterManager.AddItem(uiInventoryItem.GetFilterCategory());
				ArrayPush(wrappedItems, wrappedItem);
			};
		};
		i += 1;
	};
	filterManager.SortFiltersList();
	i = 0;
	while i < ArraySize(this.m_additionalFilters) {
		filterManager.AddFilter2(this.m_additionalFilters[i]);
		i += 1;
	}
	filterManager.AddFilter(ItemFilterCategory.AllItems);
	this.RefreshFilterButtons(filterManager.GetFiltersList());
	this.m_backpackItemsDataSource.Reset(wrappedItems);
}

// New method to add extended filters to ItemCategoryFliterManager
@addMethod(ItemCategoryFliterManager)
public final func AddFilter2(filter: ItemFilterCategory2) -> Void {
	this.AddFilter(IntEnum<ItemFilterCategory>(EnumInt(filter)));
}

// Make sure extended filter categories survive the "sorting" ItemCategoryFliterManager does
@wrapMethod(ItemCategoryFliterManager)
public final func SortFiltersList() -> Void {
	let i: Int32;
	let result: array<ItemFilterCategory>;
	if this.m_isOrderDirty {
		i = 0;
		while i < EnumInt(ItemFilterCategory2.AllCount) {
			if ArrayContains(this.m_filters, IntEnum<ItemFilterCategory>(i)) {
				ArrayPush(result, IntEnum<ItemFilterCategory>(i));
			}
			i += 1;
		}
		this.m_filters = result;
		this.m_isOrderDirty = false;
	}
}

// Fix bug where item filters don't show up when you have a single item of a given type.
// In vanilla, the `m_filtersToCheck` loop returns after the first match, which means the
// vanilla ranged weapons/melee weapons filters matches first and it exits. But since it
// removed the vanilla filter from m_filtersToCheck, a second item of that type will
// cause the filter to appear. There also appeared to be an incrementing bug, where it
// would increment after erasing from the same array. I think that means it would be
// skipping the next filter every time it had a match, so this changes it to only
// increment when there isn't an ArrayErase.
@replaceMethod(ItemCategoryFliterManager)
public final func AddItem(itemData: wref<gameItemData>) -> Void {
	let i: Int32 = 0;
	while i < ArraySize(this.m_sharedFiltersToCheck) {
		if ItemCategoryFliter.IsOfCategoryType(this.m_sharedFiltersToCheck[i], itemData) {
			if !ArrayContains(this.m_filters, this.m_sharedFiltersToCheck[i]) {
				ArrayPush(this.m_filters, this.m_sharedFiltersToCheck[i]);
			};
			ArrayErase(this.m_sharedFiltersToCheck, i);
			this.m_isOrderDirty = true;
		} else {
			i += 1;
		};
	};
	i = 0;
	while i < ArraySize(this.m_filtersToCheck) {
		if ItemCategoryFliter.IsOfCategoryType(this.m_filtersToCheck[i], itemData) {
			if !ArrayContains(this.m_filters, this.m_filtersToCheck[i]) {
				ArrayPush(this.m_filters, this.m_filtersToCheck[i]);
			};
			ArrayErase(this.m_filtersToCheck, i);
			this.m_isOrderDirty = true;
		} else {
			i += 1;
		};
	};
}

// Add HasTag method to UIInventoryItem
@addMethod(UIInventoryItem)
public final func HasTag(tag: CName) -> Bool {
	return this.m_itemData.HasTag(tag);
}

// Implement the new item filter categories
@wrapMethod(ItemCategoryFliter)
public final static func FilterItem(filter: ItemFilterCategory, wrappedData: ref<WrappedInventoryItemData>) -> Bool {
	// Extended filter categories
	if IsDefined(wrappedData.Item) {
		switch filter {
			case ItemFilterCategory2.Handgun:
				return wrappedData.Item.HasTag(n"Revolver") || wrappedData.Item.HasTag(n"Handgun");
			case ItemFilterCategory2.Automatic:
				return wrappedData.Item.HasTag(n"Rifle Assault") || wrappedData.Item.HasTag(n"SMG") || wrappedData.Item.HasTag(n"LMG");
			case ItemFilterCategory2.LongRange:
				return (wrappedData.Item.HasTag(n"Rifle Precision") || wrappedData.Item.HasTag(n"Rifle Sniper")) && !wrappedData.Item.HasTag(n"ShotgunWeapon");
			case ItemFilterCategory2.Shotgun:
				return wrappedData.Item.HasTag(n"Shotgun") || wrappedData.Item.HasTag(n"Shotgun Dual") || wrappedData.Item.HasTag(n"ShotgunWeapon");

			case ItemFilterCategory2.Thrown:
				return wrappedData.Item.HasTag(n"ThrowableWeapon");
			case ItemFilterCategory2.Blade:
				return wrappedData.Item.HasTag(n"BladeWeapon");
			case ItemFilterCategory2.Blunt:
				return wrappedData.Item.HasTag(n"BluntWeapon");

			case ItemFilterCategory2.Iconic:
				return wrappedData.Item.IsIconic();
			case ItemFilterCategory2.CraftingPart:
				return wrappedData.Item.HasTag(n"CraftingPart");
			case ItemFilterCategory2.CraftingRecipe:
				return wrappedData.Item.IsRecipe();
			case ItemFilterCategory2.Uncategorized:
				return Equals(wrappedData.Item.GetFilterCategory(), ItemFilterCategory.Invalid)
					&& !wrappedData.Item.IsQuestItem()
					&& !wrappedData.Item.HasTag(n"CraftingPart")
					&& !wrappedData.Item.IsRecipe();

			case ItemFilterCategory2.WeaponClassAll:
				return true;
			case ItemFilterCategory2.WeaponClassIconic:
				return wrappedData.Item.HasTag(n"IconicWeapon");
			case ItemFilterCategory2.WeaponClassPower:
				return wrappedData.Item.HasTag(n"PowerWeapon");
			case ItemFilterCategory2.WeaponClassTech:
				return wrappedData.Item.HasTag(n"TechWeapon");
			case ItemFilterCategory2.WeaponClassSmart:
				return wrappedData.Item.HasTag(n"SmartWeapon");
		}
	}
	// Basic filter categories
	return wrappedMethod(filter, wrappedData);
}

// Give new filter categories labels
@wrapMethod(ItemFilterCategories)
public final static func GetLabelKey(filterType: ItemFilterCategory) -> CName {
	// Check extended categories
	switch filterType {
		case ItemFilterCategory2.Handgun:
			return n"Handgun";
		case ItemFilterCategory2.Automatic:
			return n"Automatic";
		case ItemFilterCategory2.LongRange:
			return n"Long Range";
		case ItemFilterCategory2.Shotgun:
			return n"Shotgun";
		case ItemFilterCategory2.OtherRanged:
			return n"Other Ranged";

		case ItemFilterCategory2.Thrown:
			return n"Thrown";
		case ItemFilterCategory2.Blade:
			return n"Blade";
		case ItemFilterCategory2.Blunt:
			return n"Blunt";
		case ItemFilterCategory2.OtherMelee:
			return n"Other Melee";

		case ItemFilterCategory2.Iconic:
			return n"Iconic Items";
		case ItemFilterCategory2.CraftingPart:
			return n"Crafting Materials";
		case ItemFilterCategory2.CraftingRecipe:
			return n"Crafting Specs";
		case ItemFilterCategory2.Uncategorized:
			return n"Others";

		case ItemFilterCategory2.WeaponClassAll:
			return n"All";
		case ItemFilterCategory2.WeaponClassIconic:
			return n"Iconic";
		case ItemFilterCategory2.WeaponClassPower:
			return n"Power";
		case ItemFilterCategory2.WeaponClassTech:
			return n"Tech";
		case ItemFilterCategory2.WeaponClassSmart:
			return n"Smart";
	}
	// Check base categories
	return wrappedMethod(filterType);
}

// Give new filter categories icons
@wrapMethod(ItemFilterCategories)
public final static func GetIcon(filterType: ItemFilterCategory) -> String {
	// Check extended categories
	switch filterType {
		case ItemFilterCategory2.Handgun:
			return "UIIcon.Filter_Handgun";
		case ItemFilterCategory2.Automatic:
			return "UIIcon.Filter_Automatic";
		case ItemFilterCategory2.LongRange:
			return "UIIcon.Filter_LongRange";
		case ItemFilterCategory2.Shotgun:
			return "UIIcon.Filter_Shotgun";
		case ItemFilterCategory2.OtherRanged:
			return "UIIcon.Filter_OtherRanged";

		case ItemFilterCategory2.Thrown:
			return "UIIcon.Filter_Thrown";
		case ItemFilterCategory2.Blade:
			return "UIIcon.Filter_Blade";
		case ItemFilterCategory2.Blunt:
			return "UIIcon.Filter_Blunt";
		case ItemFilterCategory2.OtherMelee:
			return "UIIcon.Filter_OtherMelee";

		case ItemFilterCategory2.Iconic:
			return "UIIcon.Filter_Iconic";
		case ItemFilterCategory2.CraftingPart:
			return "UIIcon.Filter_CraftingPart";
		case ItemFilterCategory2.CraftingRecipe:
			return "UIIcon.Filter_CraftingRecipe";
		case ItemFilterCategory2.Uncategorized:
			return "UIIcon.Filter_Uncategorized";

		case ItemFilterCategory2.WeaponClassAll:
			return "UIIcon.Filter_WeaponClassAll";
		case ItemFilterCategory2.WeaponClassIconic:
			return "UIIcon.Filter_Iconic";
		case ItemFilterCategory2.WeaponClassPower:
			return "UIIcon.Filter_WeaponClassPower";
		case ItemFilterCategory2.WeaponClassTech:
			return "UIIcon.Filter_WeaponClassTech";
		case ItemFilterCategory2.WeaponClassSmart:
			return "UIIcon.Filter_WeaponClassSmart";
	}
	// Check base categories
	return wrappedMethod(filterType);
}

// Additional filters for player on FullscreenVendorGameController
@addField(FullscreenVendorGameController)
private let m_additionalPlayerFilters: array<ItemFilterCategory2>;

// Additional filters for vendor on FullscreenVendorGameController
@addField(FullscreenVendorGameController)
private let m_additionalVendorFilters: array<ItemFilterCategory2>;

// Additional filters for vendor on FullscreenVendorGameController
@addField(FullscreenVendorGameController)
private let m_additionalStorageFilters: array<ItemFilterCategory2>;

@addField(FullscreenVendorGameController)
private let modSortButtonWidthsSet: Bool = false;
@addField(FullscreenVendorGameController)
private let modPlayerSortButtonWidth: Float;
@addField(FullscreenVendorGameController)
private let modVendorSortButtonWidth: Float;

// Intialize additional filters
@wrapMethod(FullscreenVendorGameController)
private final func Init() -> Void {
	let moreWeaponFiltersConfig = MoreWeaponFiltersConfig.Get(GetGameInstance());

	ArrayClear(this.m_additionalPlayerFilters);
	ArrayClear(this.m_additionalVendorFilters);
	ArrayClear(this.m_additionalStorageFilters);

	if moreWeaponFiltersConfig.enableRangedVendorFilters {
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Handgun);
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Automatic);
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.LongRange);
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Shotgun);

		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.Handgun);
		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.Automatic);
		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.LongRange);
		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.Shotgun);

		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Handgun);
		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Automatic);
		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.LongRange);
		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Shotgun);
	}

	if moreWeaponFiltersConfig.enableMeleeVendorFilters {
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Thrown);
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Blade);
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Blunt);

		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.Thrown);
		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.Blade);
		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.Blunt);

		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Thrown);
		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Blade);
		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Blunt);
	}

	if moreWeaponFiltersConfig.enableItemVendorFilters {
		ArrayPush(this.m_additionalPlayerFilters, ItemFilterCategory2.Iconic);

		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.CraftingPart);
		ArrayPush(this.m_additionalVendorFilters, ItemFilterCategory2.CraftingRecipe);

		ArrayPush(this.m_additionalStorageFilters, ItemFilterCategory2.Iconic);
	}

	if moreWeaponFiltersConfig.enableRangedVendorFilters && moreWeaponFiltersConfig.enableMeleeVendorFilters {
		if !this.modSortButtonWidthsSet {
			this.modPlayerSortButtonWidth = inkWidgetRef.GetWidth(this.m_playerSortingButton) - 182.0;
			this.modVendorSortButtonWidth = inkWidgetRef.GetWidth(this.m_vendorSortingButton) - 182.0;
			this.modSortButtonWidthsSet = true;
		}

		// Set filter button grids to have 7 instead of 6 columns, since there's now a bunch more
		// buttons. Also decrease the width of the sort buttons to accommodate the extra space.
		let playerGridWidget = inkWidgetRef.Get(this.m_playerFiltersContainer) as inkUniformGrid;
		playerGridWidget.wrappingWidgetCount = 8u;
		inkWidgetRef.SetWidth(this.m_playerSortingButton, this.modPlayerSortButtonWidth);
		
		let vendorGridWidget = inkWidgetRef.Get(this.m_vendorFiltersContainer) as inkUniformGrid;
		vendorGridWidget.wrappingWidgetCount = 8u;
		inkWidgetRef.SetWidth(this.m_vendorSortingButton, this.modVendorSortButtonWidth);

		inkWidgetRef.SetPadding(this.m_sortingDropdown, 230, 0, 0, 0);
	} else if moreWeaponFiltersConfig.enableRangedVendorFilters || moreWeaponFiltersConfig.enableMeleeVendorFilters {
		if !this.modSortButtonWidthsSet {
			this.modPlayerSortButtonWidth = inkWidgetRef.GetWidth(this.m_playerSortingButton) - 81.0;
			this.modVendorSortButtonWidth = inkWidgetRef.GetWidth(this.m_vendorSortingButton) - 81.0;
			this.modSortButtonWidthsSet = true;
		}

		// Set filter button grids to have 7 instead of 6 columns, since there's now a bunch more
		// buttons. Also decrease the width of the sort buttons to accommodate the extra space.
		let playerGridWidget = inkWidgetRef.Get(this.m_playerFiltersContainer) as inkUniformGrid;
		playerGridWidget.wrappingWidgetCount = 7u;
		inkWidgetRef.SetWidth(this.m_playerSortingButton, this.modPlayerSortButtonWidth);
		
		let vendorGridWidget = inkWidgetRef.Get(this.m_vendorFiltersContainer) as inkUniformGrid;
		vendorGridWidget.wrappingWidgetCount = 7u;
		inkWidgetRef.SetWidth(this.m_vendorSortingButton, this.modVendorSortButtonWidth);

		inkWidgetRef.SetPadding(this.m_sortingDropdown, 82.5, 0, 0, 0);
	}

	wrappedMethod();
}

// Add new filters to FullscreenVendorGameController
@wrapMethod(FullscreenVendorGameController)
private final func SetFilters(root: inkWidgetRef, const data: script_ref<array<Int32>>, callback: CName) -> Void {
	// Extend player filters
	let i: Int32;
	if root == this.m_playerFiltersContainer {
		i = 0;
		while i < ArraySize(this.m_additionalPlayerFilters) {
			this.m_playerFilterManager.AddFilter2(this.m_additionalPlayerFilters[i]);
			i += 1;
		}
		data = this.m_playerFilterManager.GetIntFiltersList();
	}
	// Extend vendor filters
	if root == this.m_vendorFiltersContainer {
		if IsDefined(this.m_storageUserData) {
			i = 0;
			while i < ArraySize(this.m_additionalStorageFilters) {
				this.m_vendorFilterManager.AddFilter2(this.m_additionalStorageFilters[i]);
				i += 1;
			}
			data = this.m_vendorFilterManager.GetIntFiltersList();
		} else {
			// Drop points don't need additional filters as they have nothing to sell
			let dropPoint: ref<DropPoint> = this.m_VendorDataManager.GetVendorInstance() as DropPoint;
			if !IsDefined(dropPoint) {
				i = 0;
				while i < ArraySize(this.m_additionalVendorFilters) {
					this.m_vendorFilterManager.AddFilter2(this.m_additionalVendorFilters[i]);
					FTLog(">>> ADD: " + EnumInt(this.m_additionalVendorFilters[i]));
					i += 1;
				}
				data = this.m_vendorFilterManager.GetIntFiltersList();
			}
		}
	}
	// Call original method
	wrappedMethod(root, data, callback);
}

// ========= Weapon Equip Menu Filters =========

@wrapMethod(InventoryItemModeLogicController)
private final func SetupFiltersToCheck(equipmentArea: gamedataEquipmentArea) -> Void {
	let moreWeaponFiltersConfig = MoreWeaponFiltersConfig.Get(GetGameInstance());

	wrappedMethod(equipmentArea);
	if Equals(equipmentArea, gamedataEquipmentArea.Weapon) {
		if moreWeaponFiltersConfig.enableRangedEquipFilters {
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Handgun)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Automatic)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.LongRange)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Shotgun)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherRanged)));
		}
		if moreWeaponFiltersConfig.enableMeleeEquipFilters {
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Thrown)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blade)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blunt)));
			this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherMelee)));
		}
	};
}

@wrapMethod(ItemCategoryFliter)
public final static func IsOfCategoryType( filter : ItemFilterCategory, data : wref< gameItemData > ) -> Bool {
	if !IsDefined(data) {
		return false;
	};
	switch filter {
		case ItemFilterCategory2.Handgun:
			return data.HasTag(n"Revolver") || data.HasTag(n"Handgun");
		case ItemFilterCategory2.Automatic:
			return data.HasTag(n"Rifle Assault") || data.HasTag(n"SMG") || data.HasTag(n"LMG");
		case ItemFilterCategory2.LongRange:
			return (data.HasTag(n"Rifle Precision") || data.HasTag(n"Rifle Sniper")) && !data.HasTag(n"ShotgunWeapon");
		case ItemFilterCategory2.Shotgun:
			return data.HasTag(n"Shotgun") || data.HasTag(n"Shotgun Dual") || data.HasTag(n"ShotgunWeapon");
		case ItemFilterCategory2.OtherRanged:
			return data.HasTag(n"RangedWeapon") &&
				!data.HasTag(n"Revolver") &&
				!data.HasTag(n"Handgun") &&
				!data.HasTag(n"Rifle Assault") &&
				!data.HasTag(n"SMG") &&
				!data.HasTag(n"LMG") &&
				!data.HasTag(n"Rifle Precision") &&
				!data.HasTag(n"Rifle Sniper") &&
				!data.HasTag(n"Shotgun") &&
				!data.HasTag(n"Shotgun Dual") &&
				!data.HasTag(n"ShotgunWeapon");

		case ItemFilterCategory2.Thrown:
			return data.HasTag(n"ThrowableWeapon");
		case ItemFilterCategory2.Blade:
			return data.HasTag(n"BladeWeapon");
		case ItemFilterCategory2.Blunt:
			return data.HasTag(n"BluntWeapon");
		case ItemFilterCategory2.OtherMelee:
			return data.HasTag(n"MeleeWeapon") &&
				!data.HasTag(n"ThrowableWeapon") &&
				!data.HasTag(n"BladeWeapon") &&
				!data.HasTag(n"BluntWeapon");

		case ItemFilterCategory2.WeaponClassAll:
			return true;
		case ItemFilterCategory2.WeaponClassIconic:
			return data.HasTag(n"IconicWeapon");
		case ItemFilterCategory2.WeaponClassPower:
			return data.HasTag(n"PowerWeapon");
		case ItemFilterCategory2.WeaponClassTech:
			return data.HasTag(n"TechWeapon");
		case ItemFilterCategory2.WeaponClassSmart:
			return data.HasTag(n"SmartWeapon");
	}
	return wrappedMethod(filter, data);
}

@wrapMethod(InventoryItemModeLogicController)
private final func UpdateAvailableItems(opt keepCurrentFilter: Bool) -> Void {
	let attachments: array<ref<InventoryItemAttachments>>;
	let attachmentsToCheck: array<TweakDBID>;
	let availableItems: array<InventoryItemData>;
	let i: Int32;
	let targetFilter: Int32;
	let isWeapon: Bool = this.IsEquipmentAreaWeapon(this.m_lastEquipmentAreas);
	let isClothing: Bool = this.IsEquipmentAreaClothing(this.m_lastEquipmentAreas);
	let isOutfit: Bool = ArrayContains(this.m_lastEquipmentAreas, gamedataEquipmentArea.Outfit);
	this.m_itemGridContainerController.SetSize(isOutfit ? ItemModeGridSize.Outfit : ItemModeGridSize.Default);
	if isWeapon || isClothing {
		if isWeapon && this.m_leftHandWeaponOnly {
			this.m_InventoryManager.GetPlayerDualWieldInventoryDataRef(true, this.m_itemDropQueue, availableItems);
		} else {
			this.m_InventoryManager.GetPlayerInventoryDataRef(this.m_lastEquipmentAreas, true, this.m_itemDropQueue, availableItems);
		};
		attachments = InventoryItemData.GetAttachments(this.m_selectedItemChooser.GetModifiedItemData());
		if TDBID.IsValid(this.m_selectedItemChooser.GetSelectedSlotID()) {
			ArrayPush(attachmentsToCheck, this.m_selectedItemChooser.GetSelectedSlotID());
		} else {
			i = 0;
			while i < ArraySize(attachments) {
				if Equals(attachments[i].SlotType, InventoryItemAttachmentType.Generic) {
					ArrayPush(attachmentsToCheck, attachments[i].SlotID);
				};
				i += 1;
			};
		};
		this.m_InventoryManager.GetPlayerInventoryPartsForItemRef(this.m_selectedItemChooser.GetModifiedItemID(), attachmentsToCheck, this.m_itemDropQueue, availableItems);
	} else {
		if Equals(this.m_viewMode, ItemViewModes.Mod) {
			availableItems = this.m_InventoryManager.GetPlayerInventoryPartsForItem((this.itemChooser as InventoryCyberwareItemChooser).GetModifiedItemID(), this.itemChooser.GetSelectedItem().GetSlotID());
		} else {
			this.m_InventoryManager.GetPlayerInventoryDataRef(this.m_lastEquipmentAreas, true, this.m_itemDropQueue, availableItems);
		};
	};
	this.m_itemGridDataView.DisableSorting();
	this.UpdateAvailableItemsGrid(availableItems);
	this.CreateFilterButtons(this.m_itemGridContainerController.GetFiltersGrid());
	this.m_itemGridDataView.EnableSorting();
	if (isWeapon || isClothing) && !keepCurrentFilter {
		if Equals(this.m_viewMode, ItemViewModes.Mod) && this.GetFilterButtonIndex(ItemFilterCategory.Attachments) >= 0 {
			this.SelectFilterButton(ItemFilterCategory.Attachments);
		} else {
			targetFilter = -1;
			if isWeapon {
				if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Handgun))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Handgun))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Handgun)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Automatic))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Automatic))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Automatic)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.LongRange))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.LongRange))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.LongRange)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Shotgun))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Shotgun))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Shotgun)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherRanged))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherRanged))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherRanged)));
				} else if Equals(this.m_currentFilter, ItemFilterCategory.RangedWeapons) && this.GetFilterButtonIndex(ItemFilterCategory.RangedWeapons) >= 0 {
					targetFilter = this.GetFilterButtonIndex(ItemFilterCategory.RangedWeapons);
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Thrown))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Thrown))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Thrown)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blade))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blade))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blade)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blunt))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blunt))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Blunt)));
				} else if Equals(this.m_currentFilter, IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherMelee))) && this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherMelee))) >= 0 {
					targetFilter = this.GetFilterButtonIndex(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherMelee)));
				} else {
					if Equals(this.m_currentFilter, ItemFilterCategory.MeleeWeapons) && this.GetFilterButtonIndex(ItemFilterCategory.MeleeWeapons) >= 0 {
						targetFilter = this.GetFilterButtonIndex(ItemFilterCategory.MeleeWeapons);
					};
				};
			} else {
				if isClothing {
					targetFilter = this.GetFilterButtonIndex(ItemFilterCategory.Clothes);
				};
			};
			if targetFilter == -1 {
				targetFilter = 0;
			};
			this.SelectFilterButtonByIndex(targetFilter);
		};
	} else {
		this.m_itemGridDataView.Sort();
	};
}

// ========= Weapon class filters =========

@addField(ItemModeGridView)
public let modWeaponClassFilter: ItemFilterCategory = ItemFilterCategory.AllItems;

@addMethod(ItemModeGridView)
public final func ModSetWeaponClassFilter(filter: ItemFilterCategory) -> Void {
	this.modWeaponClassFilter = filter;
	this.Filter();
}

// AND the normal filter with the weapon class filter when filtering items
@replaceMethod(ItemModeGridView)
public func FilterItem(data: ref<IScriptable>) -> Bool {
	let m_wrappedData: ref<WrappedInventoryItemData> = data as WrappedInventoryItemData;
	let classFilter: ItemFilterCategory = this.modWeaponClassFilter;
	if Equals(classFilter, ItemFilterCategory.AllItems) || Equals(classFilter, ItemFilterCategory.Invalid) {
		return ItemCategoryFliter.FilterItem(this.m_itemFilterType, m_wrappedData);
	};
	return ItemCategoryFliter.FilterItem(this.m_itemFilterType, m_wrappedData)
		&& ItemCategoryFliter.FilterItem(classFilter, m_wrappedData);
}
