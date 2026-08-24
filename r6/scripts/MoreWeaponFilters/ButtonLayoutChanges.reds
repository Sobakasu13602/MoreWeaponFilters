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

@addField(InventoryItemModeLogicController)
private let modWeaponClassFilter: ItemFilterCategory2 = ItemFilterCategory2.WeaponClassAll;
@addField(InventoryItemModeLogicController)
private let modClassFilterButtons: [wref<BackpackFilterButtonController>];

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
		ArrayClear(this.modClassFilterButtons);
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

		if this.moreWeaponFiltersConfig.enableWeaponClassEquipFilters && this.IsEquipmentAreaWeapon(this.m_lastEquipmentAreas) {
			this.ModSpawnWeaponClassFilterRow(inkWidgetRef.Get(targetWidget) as inkCompoundWidget);
		};
	};
}

// Spawn the weapon class sub-filters above the normal filters
@addMethod(InventoryItemModeLogicController)
private final func ModSpawnWeaponClassFilterRow(parent: ref<inkCompoundWidget>) -> Void {
	let filterButton: ref<BackpackFilterButtonController>;
	let classes: array<ItemFilterCategory2> = [
		ItemFilterCategory2.WeaponClassAll,
		ItemFilterCategory2.WeaponClassIconic,
		ItemFilterCategory2.WeaponClassPower,
		ItemFilterCategory2.WeaponClassTech,
		ItemFilterCategory2.WeaponClassSmart
	];
	let i: Int32;


	// Offsets for the buttons so they're moved to above the normal filters. The x offset
	// is based on the number of normal buttons since these buttons are added to the same
	// parent container as them. e.g. if you have normal buttons n, and class buttons c,
	// it would look like this without offsets:
	// | n | n | n | c | c |
	// So to move them, in addition to a y offset, it needs to offset x for each `n`
	// button by `width(button) * len(n_buttons)`, so that it looks like:
	// | c | c |
	// | n | n | n |
	let primaryCount: Int32 = inkCompoundRef.GetNumChildren(this.m_filterButtonsGrid);
	let xOffset: Float = -148.0 * Cast<Float>(primaryCount);
	let yOffset: Float;

	if Equals(this.moreWeaponFiltersConfig.extraFilterPosition, ExtraFilterButtonsPosition.Above) {
		if this.moreWeaponFiltersConfig.moveFilterButtonsUp {
			// Extra filters are already above and the buttons are moved up, so only empty space is below main filters
			yOffset = 104.0;
		} else {
			// Extra filters are above, but there's still room above that, so move the class filters up two rows
			yOffset = -104.0 - 87.0;
		}
	} else {
		// Extra filters are inline/below, and it doesn't matter if the filters are moved up since that offset also
		// applies to these buttons
		yOffset = -104.0;
	}

	i = 0;
	while i < ArraySize(classes) {
		filterButton = this.SpawnFromLocal(parent, n"filterButtonItem").GetController() as BackpackFilterButtonController;
		filterButton.RegisterToCallback(n"OnRelease", this, n"ModOnWeaponClassFilterClick");
		filterButton.RegisterToCallback(n"OnHoverOver", this, n"OnItemFilterHoverOver");
		filterButton.RegisterToCallback(n"OnHoverOut", this, n"OnItemFilterHoverOut");
		filterButton.Setup(IntEnum<ItemFilterCategory>(EnumInt(classes[i])));

		filterButton.GetRootWidget().SetTranslation(new Vector2(xOffset, yOffset));

		ArrayPush(this.modClassFilterButtons, filterButton);
		i += 1;
	};

	this.ModSetActiveClassFilter(this.modWeaponClassFilter);
	this.ModUpdateWeaponClassFilterVisibility(this.m_savedFilter);
}

// Equivalent of `OnItemFilterClick` that sets the active class filter instead
@addMethod(InventoryItemModeLogicController)
protected cb func ModOnWeaponClassFilterClick(evt: ref<inkPointerEvent>) -> Bool {
	let controller: ref<BackpackFilterButtonController>;
	let widget: ref<inkWidget>;
	if evt.IsAction(n"click") {
		widget = evt.GetCurrentTarget();
		controller = widget.GetController() as BackpackFilterButtonController;
		this.ModSetActiveClassFilter(IntEnum<ItemFilterCategory2>(EnumInt(controller.GetFilterType())));
		this.PlayLibraryAnimation(n"inventory_grid_filter_change");
		this.PlaySound(n"Button", n"OnPress");
	};
}

// Selects a weapon class filter. Updates the active button, the stored class
// filter, and the grid view
@addMethod(InventoryItemModeLogicController)
private final func ModSetActiveClassFilter(classFilter: ItemFilterCategory2) -> Void {
	let i: Int32 = 0;
	while i < ArraySize(this.modClassFilterButtons) {
		let button: wref<BackpackFilterButtonController> = this.modClassFilterButtons[i];
		if IsDefined(button) {
			let match: Bool = Equals(IntEnum<ItemFilterCategory2>(EnumInt(button.GetFilterType())), classFilter);
			button.SetActive(match);
		};
		i += 1;
	};
	this.modWeaponClassFilter = classFilter;
	this.m_itemGridDataView.ModSetWeaponClassFilter(IntEnum<ItemFilterCategory>(EnumInt(classFilter)));
}

// Whether the given filter is a melee category
@addMethod(InventoryItemModeLogicController)
private final func ModIsMeleeFilter(filter: ItemFilterCategory) -> Bool {
	switch filter {
		case ItemFilterCategory2.MeleeWeapons:
		case ItemFilterCategory2.Thrown:
		case ItemFilterCategory2.Blade:
		case ItemFilterCategory2.Blunt:
		case ItemFilterCategory2.OtherMelee:
			return true;
	};
	return false;
}

// Whether a given sub-filter is only for ranged weapons
@addMethod(InventoryItemModeLogicController)
private final func ModIsRangedOnlyFilter(filter: ItemFilterCategory) -> Bool {
	switch filter {
		case ItemFilterCategory2.WeaponClassPower:
		case ItemFilterCategory2.WeaponClassTech:
		case ItemFilterCategory2.WeaponClassSmart:
			return true;
	};
	return false;
}

// Hide power/tech/smart sub-filters when melee filters are selected. Hide all
// sub-filters when mods are selected
@addMethod(InventoryItemModeLogicController)
private final func ModUpdateWeaponClassFilterVisibility(currentFilter: ItemFilterCategory) -> Void {
	if ArraySize(this.modClassFilterButtons) == 0 {
		return;
	};
	let hideAll: Bool = Equals(currentFilter, ItemFilterCategory.Attachments);
	let hideGunOnly: Bool = this.ModIsMeleeFilter(currentFilter);
	if hideAll || (hideGunOnly && this.ModIsRangedOnlyFilter(IntEnum<ItemFilterCategory>(EnumInt(this.modWeaponClassFilter)))) {
		this.ModSetActiveClassFilter(ItemFilterCategory2.WeaponClassAll);
	};
	let i: Int32 = 0;
	while i < ArraySize(this.modClassFilterButtons) {
		let button: wref<BackpackFilterButtonController> = this.modClassFilterButtons[i];
		if IsDefined(button) {
			let visible: Bool = !hideAll && (!hideGunOnly || !this.ModIsRangedOnlyFilter(button.GetFilterType()));
			button.GetRootWidget().SetVisible(visible);
		};
		i += 1;
	};
}

// Update the sub-filter visibility whenever the normal filters change, so Power/Tech/Smart will
// be hidden for melee weapons
@wrapMethod(InventoryItemModeLogicController)
private final func SetActiveFilterController(controller: ref<BackpackFilterButtonController>) -> Void {
	wrappedMethod(controller);
	this.ModUpdateWeaponClassFilterVisibility(controller.GetFilterType());
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

// Increase scale of melee icons and decrease calse of weapon class icons
@wrapMethod(BackpackFilterButtonController)
public final func Setup(filterType: ItemFilterCategory) -> Void {
	if EnumInt(filterType) >= EnumInt(ItemFilterCategory2.Thrown) && EnumInt(filterType) <= EnumInt(ItemFilterCategory2.Blunt) {
		inkWidgetRef.SetScale(this.m_icon, new Vector2(2.3, 2.3));
	} else if EnumInt(filterType) >= EnumInt(ItemFilterCategory2.WeaponClassPower) && EnumInt(filterType) <= EnumInt(ItemFilterCategory2.WeaponClassSmart) {
		inkWidgetRef.SetScale(this.m_icon, new Vector2(0.8, 0.8));
	} else {
		inkWidgetRef.SetScale(this.m_icon, new Vector2(1, 1));
	}
	wrappedMethod(filterType);

}

@addField(FilterRadioGroup)
public let modScaleMelee: Bool = false;

@wrapMethod(FullscreenVendorGameController)
private final func SetFilters(root: inkWidgetRef, const data: script_ref<[Int32]>, callback: CName) -> Void {
	let radioGroup: ref<FilterRadioGroup> = inkWidgetRef.GetControllerByType(root, n"FilterRadioGroup") as FilterRadioGroup;
	radioGroup.modScaleMelee = true;
	wrappedMethod(root, data, callback);
}

@wrapMethod(FilterRadioGroup)
public final func SetData(const data: script_ref<[Int32]>, opt tooltipsManager: wref<gameuiTooltipsManager>, opt tooltipIndex: Int32) -> Void {
	wrappedMethod(data, tooltipsManager, tooltipIndex);
	let filterToggle: ref<ToggleController>;
	let i: Int32 = 0;
	while i < ArraySize(Deref(data)) {
		filterToggle = this.m_toggles[i] as ToggleController;
		if this.modScaleMelee && Deref(data)[i] >= EnumInt(ItemFilterCategory2.Thrown) && Deref(data)[i] <= EnumInt(ItemFilterCategory2.Blunt) {
			filterToggle.SetMeleeScale();
		} else if this.modScaleMelee {
			filterToggle.SetOrigScale();
		}
		i += 1;
	};
}

@addField(ToggleController)
private let modOriginalScaleSet: Bool = false;

@addField(ToggleController)
private let modOriginalScale: Vector2;

@addMethod(ToggleController)
public final func SetMeleeScale() -> Void {
	if !this.modOriginalScaleSet {
		this.modOriginalScale = inkWidgetRef.GetScale(this.m_icon);
		this.modOriginalScaleSet = true;
	}
	inkWidgetRef.SetScale(this.m_icon, new Vector2(2.3, 2.3));
}

@addMethod(ToggleController)
public final func SetOrigScale() -> Void {
	if this.modOriginalScaleSet {
		inkWidgetRef.SetScale(this.m_icon, this.modOriginalScale);
	}
}
