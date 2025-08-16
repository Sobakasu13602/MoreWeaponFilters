module MoreWeaponFilters

@addField(InventoryItemModeLogicController)
private let moreWeaponFiltersConfig: ref<MoreWeaponFiltersConfig>;

@addField(InventoryItemModeLogicController)
private let modDefaultFilterButtonOffset: Vector2;
@addField(InventoryItemModeLogicController)
private let modFilterButtonDefaultsSet: Bool = false;

@addField(InventoryItemModeLogicController)
private let modDefaultSortButtonOffset: Vector2;
@addField(InventoryItemModeLogicController)
private let modDefaultSortDropdownPadding: inkMargin;
@addField(InventoryItemModeLogicController)
private let modSortButtonDefaultsSet: Bool = false;

@wrapMethod(InventoryItemModeLogicController)
protected cb func OnInitialize() -> Bool {
	this.moreWeaponFiltersConfig = MoreWeaponFiltersConfig.Get(GetGameInstance());
	return wrappedMethod();
}

@wrapMethod(InventoryItemModeLogicController)
private final func SetEquipmentArea(equipmentArea: gamedataEquipmentArea) -> Void {
	wrappedMethod(equipmentArea);

	// move the filter buttons up in the equipment area if enabled, or otherwise move it back to
	// its original location if in another menu and it was moved previously
	if this.moreWeaponFiltersConfig.moveFilterButtonsUp && this.IsEquipmentAreaWeapon(this.m_lastEquipmentAreas) {
		if !this.modFilterButtonDefaultsSet {
			this.modDefaultFilterButtonOffset = inkWidgetRef.GetTranslation(this.m_filterButtonsGrid);
			this.modFilterButtonDefaultsSet = true;
		}
		inkWidgetRef.SetTranslation(this.m_filterButtonsGrid, this.modDefaultFilterButtonOffset.X, this.modDefaultFilterButtonOffset.Y - 87.0);
	} else if this.modFilterButtonDefaultsSet {
		inkWidgetRef.SetTranslation(this.m_filterButtonsGrid, this.modDefaultFilterButtonOffset);
	}

	// move the sort button up in the equipment area if enabled, or otherwise move it back to
	// its original location if in another menu and it was moved previously
	if this.moreWeaponFiltersConfig.moveSortButtonDown && this.IsEquipmentAreaWeapon(this.m_lastEquipmentAreas) {
		let sortingButton = this.m_inventoryController.ModGetSortingButton();
		let sortingDropdown = this.m_inventoryController.ModGetSortingDropdown();
		if !this.modSortButtonDefaultsSet {
			this.modDefaultSortButtonOffset = inkWidgetRef.GetTranslation(sortingButton);
			this.modDefaultSortDropdownPadding = inkWidgetRef.GetPadding(sortingDropdown);
			this.modSortButtonDefaultsSet = true;
		}
		inkWidgetRef.SetTranslation(sortingButton, this.modDefaultSortButtonOffset.X, this.modDefaultSortButtonOffset.Y + 82.0);
		inkWidgetRef.SetPadding(sortingDropdown,
			this.modDefaultSortDropdownPadding.left,
			this.modDefaultSortDropdownPadding.top + 82.0,
			this.modDefaultSortDropdownPadding.right,
			this.modDefaultSortDropdownPadding.bottom
		);
	} else if this.modSortButtonDefaultsSet {
		let sortingButton = this.m_inventoryController.ModGetSortingButton();
		let sortingDropdown = this.m_inventoryController.ModGetSortingDropdown();
		inkWidgetRef.SetTranslation(sortingButton, this.modDefaultSortButtonOffset);
		inkWidgetRef.SetPadding(sortingDropdown, this.modDefaultSortDropdownPadding);
	}
}

@addMethod(gameuiInventoryGameController)
public final func ModGetSortingButton() -> inkWidgetRef {
	return this.m_sortingButton;
}
@addMethod(gameuiInventoryGameController)
public final func ModGetSortingDropdown() -> inkWidgetRef {
	return this.m_sortingDropdown;
}

// control placement of new filter buttons
@replaceMethod(InventoryItemModeLogicController)
private final func CreateFilterButtons(targetWidget: inkCompoundRef, opt equipmentArea: gamedataEquipmentArea) -> Void {
	let filterButton: ref<BackpackFilterButtonController>;
	let filters: array<ItemFilterCategory>;
	let i: Int32;
	if !ArrayContains(this.m_lastEquipmentAreas, equipmentArea) {
		filters = this.m_filterManager.GetSortedFiltersList();
		inkCompoundRef.RemoveAllChildren(this.m_filterButtonsGrid);
		i = 0;

		let isInline = Equals(this.moreWeaponFiltersConfig.extraFilterPosition, ExtraFilterButtonsPosition.Inline);
		let xOffset: Float;
		let xOffsetSet: Bool = false;
		let yOffset: Float = Equals(this.moreWeaponFiltersConfig.extraFilterPosition, ExtraFilterButtonsPosition.Above) ? -87.0 :
			this.moreWeaponFiltersConfig.moveFilterButtonsUp ? 87.0 : 82.0;
		while i < ArraySize(filters) {
			filterButton = this.SpawnFromLocal(inkWidgetRef.Get(targetWidget) as inkCompoundWidget, n"filterButtonItem").GetController() as BackpackFilterButtonController;
			filterButton.RegisterToCallback(n"OnRelease", this, n"OnItemFilterClick");
			filterButton.RegisterToCallback(n"OnHoverOver", this, n"OnItemFilterHoverOver");
			filterButton.RegisterToCallback(n"OnHoverOut", this, n"OnItemFilterHoverOut");
			filterButton.Setup(filters[i]);
			if Equals(filters[i], this.m_savedFilter) {
				filterButton.SetActive(true);
				this.m_activeFilter = filterButton;
			};

			if !isInline && EnumInt(filters[i]) >= EnumInt(ItemFilterCategory2.Handgun) {
				if !xOffsetSet {
					xOffsetSet = true;
					xOffset = -148.0 * Cast<Float>(i);
				}
				filterButton.GetRootWidget().SetTranslation(new Vector2(xOffset, yOffset));
			}

			ArrayPush(this.m_filters, filterButton);
			inkWidgetRef.SetVisible(this.m_prevFilterHint, i > 0);
			inkWidgetRef.SetVisible(this.m_nextFilterHint, i > 0);
			i += 1;
		};
	};
}

// keep selected filter on equip/unequip

@wrapMethod(InventoryItemModeLogicController)
protected cb func OnDelayedItemEquipped(evt: ref<DelayedItemEquipped>) -> Bool {
	let filter = this.m_currentFilter;
	let result = wrappedMethod(evt);
	if this.moreWeaponFiltersConfig.keepFilterSelectOnEquip && !Equals(this.m_currentFilter, filter) {
		this.m_currentFilter = filter;
		this.RefreshAvailableItems();
		this.m_comparisonResolver.FlushCache();
	}
	return result;
}

@wrapMethod(InventoryItemModeLogicController)
private final func HandleItemClick(const itemData: script_ref<InventoryItemData>, actionName: ref<inkActionName>, opt displayContext: ItemDisplayContext, opt isPlayerLocked: Bool) -> Void {
	let filter = this.m_currentFilter;
	wrappedMethod(itemData, actionName, displayContext, isPlayerLocked);
	if this.moreWeaponFiltersConfig.keepFilterSelectOnEquip && !Equals(this.m_currentFilter, filter) {
		this.m_currentFilter = filter;
		this.RefreshAvailableItems();
		this.NotifyItemUpdate();
	}
}

@wrapMethod(InventoryItemModeLogicController)
protected cb func OnItemChooserUnequipItem(evt: ref<ItemChooserUnequipItem>) -> Bool {
	let filter = this.m_currentFilter;
	let result = wrappedMethod(evt);
	if this.moreWeaponFiltersConfig.keepFilterSelectOnEquip && !Equals(this.m_currentFilter, filter) {
		this.m_currentFilter = filter;
		this.RefreshAvailableItems();
		this.NotifyItemUpdate();
		this.itemChooser.RefreshItems();
	}
	return result;
}
