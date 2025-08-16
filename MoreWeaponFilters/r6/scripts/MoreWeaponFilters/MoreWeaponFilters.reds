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
	AllCount = 25,
}

// Refactor PopulateInventory, change local tagsToFilterOut variable into m_tagsToFilterOut field.
@addField(BackpackMainGameController)
private let m_tagsToFilterOut: array<CName>;

// Additional filters are controlled by the m_additionalFilters field.
@addField(BackpackMainGameController)
private let m_additionalFilters: array<ItemFilterCategory2>;

// Set inventory blacklist (quickhacks are no longer on it), and additional filters
@wrapMethod(BackpackMainGameController)
protected cb func OnInitialize() -> Bool {
	ArrayPush(this.m_tagsToFilterOut, n"HideInBackpackUI");
	ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Handgun);
	ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Automatic);
	ArrayPush(this.m_additionalFilters, ItemFilterCategory2.LongRange);
	ArrayPush(this.m_additionalFilters, ItemFilterCategory2.Shotgun);
	return wrappedMethod();
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

	if moreWeaponFiltersConfig.enableVendorFilters {
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
	wrappedMethod(equipmentArea);
	if Equals(equipmentArea, gamedataEquipmentArea.Weapon) {
		this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Handgun)));
		this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Automatic)));
		this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.LongRange)));
		this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.Shotgun)));
		this.m_filterManager.AddFilterToCheck(IntEnum<ItemFilterCategory>(EnumInt(ItemFilterCategory2.OtherRanged)));
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
	}
	return wrappedMethod(filter, data);
}

@wrapMethod(InventoryItemModeLogicController)
private final func UpdateAvailableItems() -> Void {
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
		this.m_InventoryManager.GetPlayerInventoryDataRef(this.m_lastEquipmentAreas, true, this.m_itemDropQueue, availableItems);
		attachments = InventoryItemData.GetAttachments(this.itemChooser.GetModifiedItemData());
		if TDBID.IsValid(this.itemChooser.GetSelectedSlotID()) {
			ArrayPush(attachmentsToCheck, this.itemChooser.GetSelectedSlotID());
		} else {
			i = 0;
			while i < ArraySize(attachments) {
				if Equals(attachments[i].SlotType, InventoryItemAttachmentType.Generic) {
					ArrayPush(attachmentsToCheck, attachments[i].SlotID);
				};
				i += 1;
			};
		};
		this.m_InventoryManager.GetPlayerInventoryPartsForItemRef(this.itemChooser.GetModifiedItemID(), attachmentsToCheck, availableItems);
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
	if isWeapon || isClothing {
		this.m_lastSelectedDisplay = this.itemChooser.GetSelectedItem();
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
