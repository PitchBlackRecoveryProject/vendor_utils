WORK_PATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/zip
TARGET_DIR := $(WORK_PATH)/..
BUILD_TOP := $(TOP)

# --- Version Extraction ---
VERSION := $(shell grep "define PB_MAIN_VERSION" $(BUILD_TOP)/bootable/recovery/variables.h | awk -F '"' '{print $$2}')
PB_VENDOR := vendor/utils

# --- Official Status Check ---
ifeq ($(PB_OFFICIAL),true)
    PB_BUILD_TYPE := OFFICIAL
    # Verify device against official list (silence output, check exit code)
    ifneq ($(shell python3 $(BUILD_TOP)/vendor/utils/pb_devices.py verify all $(TARGET_DEVICE) > /dev/null 2>&1; echo $$?),0)
        $(call error Device $(TARGET_DEVICE) is not listed as official!)
    endif
else ifeq ($(BETA_BUILD),true)
    PB_BUILD_TYPE := BETA
    ifneq ($(shell python3 $(BUILD_TOP)/vendor/utils/pb_devices.py verify all $(TARGET_DEVICE) > /dev/null 2>&1; echo $$?),0)
        $(call error Device $(TARGET_DEVICE) is not listed as official!)
    endif
else
    PB_BUILD_TYPE := UNOFFICIAL
endif

ZIP_NAME := PBRP-$(TARGET_DEVICE)-$(VERSION)-$(shell date +%Y%m%d-%H%M)-$(PB_BUILD_TYPE).zip
KEYCHECK := $(TARGET_DIR)/recovery/root/sbin/keycheck

# --- Partitioning Logic ---
ifeq ($(AB_OTA_UPDATER),true)
    AB := true
else
    AB := false
endif

# --- Determine Image Type & Source ---
# 1. Recovery as Boot
ifeq ($(BOARD_USES_RECOVERY_AS_BOOT), true)
    RECOVERY_AS_BOOT := true
    VENDOR_BOOT_RECOVERY := false
    # We zip the ramdisk cpio; the script patches the kernel
    RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/ramdisk-recovery.cpio
    pbrpimage := $(INSTALLED_BOOTIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)

# 2. Vendor Boot
else ifeq ($(BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT), true)
    RECOVERY_AS_BOOT := false
    VENDOR_BOOT_RECOVERY := true
    # We zip the full vendor_boot image; the script extracts the ramdisk from it
    RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/vendor_boot.img
    pbrpimage := $(INSTALLED_VENDOR_BOOTIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)

# 3. Traditional Recovery (A-only or A/B with dedicated recovery)
else
    RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/recovery.img
    RECOVERY_AS_BOOT := false
    VENDOR_BOOT_RECOVERY := false
    # We zip the full recovery image
    pbrpimage := $(INSTALLED_RECOVERYIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)
endif

# --- Main Build Task ---
.PHONY: pbrp
pbrp: $(pbrpimage)
	$(hide) echo "----------------------------------------------"
	$(hide) echo "Building PBRP Zip for $(TARGET_DEVICE)..."
	$(hide) echo "Mode: AB=$(AB) | RecAsBoot=$(RECOVERY_AS_BOOT) | VendorBoot=$(VENDOR_BOOT_RECOVERY)"
	
	# Cleanup previous builds
	$(hide) rm -f $(TARGET_DIR)/PBRP-*.zip
	$(hide) rm -rf $(WORK_PATH) && mkdir -p $(WORK_PATH)
	
	# 1. Copy PBRP Tools & Files
	$(hide) rsync -avp $(PB_VENDOR)/PBRP $(WORK_PATH)/
	
	# 2. Prepare Metadata & Updater
	$(hide) mkdir -p $(WORK_PATH)/META-INF/com/google/android
	$(hide) rsync -avp $(PB_VENDOR)/updater/update-* $(WORK_PATH)/META-INF/com/google/android/
	
	# 3. Config Injection
	# We replace placeholders in update-binary with actual build variables
	$(hide) sed -i "s/{version}/v$(VERSION)/g" $(WORK_PATH)/META-INF/com/google/android/update-binary
	$(hide) sed -i "s/IS_AB=false/IS_AB=$(AB)/" $(WORK_PATH)/META-INF/com/google/android/update-binary
	$(hide) sed -i "s/IS_RECOVERY_AS_BOOT=false/IS_RECOVERY_AS_BOOT=$(RECOVERY_AS_BOOT)/" $(WORK_PATH)/META-INF/com/google/android/update-binary
	$(hide) sed -i "s/IS_VENDOR_BOOT=false/IS_VENDOR_BOOT=$(VENDOR_BOOT_RECOVERY)/" $(WORK_PATH)/META-INF/com/google/android/update-binary
	
	# 4. Copy Helpers (Awk, Magiskboot, Keycheck)
	$(hide) rsync -avp $(PB_VENDOR)/updater/awk $(WORK_PATH)/META-INF/
	$(hide) cp -f $(BUILD_TOP)/external/magisk-prebuilt/prebuilt/magiskboot_arm $(WORK_PATH)/magiskboot
	$(hide) chmod 755 $(WORK_PATH)/magiskboot
	$(hide) if [ -f "$(KEYCHECK)" ]; then cp "$(KEYCHECK)" $(WORK_PATH)/META-INF/; fi
	
	# 5. Copy the Recovery Image
	$(hide) cp "$(RECOVERYPATH)" $(WORK_PATH)/
	
	# 6. Zip Creation
	$(hide) cd $(WORK_PATH) && zip -r $(ZIP_NAME) *
	$(hide) mv $(WORK_PATH)/$(ZIP_NAME) $(TARGET_DIR)/
	
	# 7. Final Output
	$(hide) if [ -f $(BUILD_TOP)/vendor/utils/.pb.1 ]; then cat $(BUILD_TOP)/vendor/utils/.pb.1; fi
	@echo "----------------------------------------------"
	@printf "Build Type: %s\n" "$(PB_BUILD_TYPE)"
	@printf "Recovery Image:    %s\n" "$(RECOVERYPATH)"
	@printf "Size:       %s\n" "$$(du -h $(RECOVERYPATH) | awk '{print $$1}')"
	@printf "Flashable Zip: %s\n" "$(TARGET_DIR)/$(ZIP_NAME)"
	@printf "Size: %s\n" "$$(du -h $(TARGET_DIR)/$(ZIP_NAME) | awk '{print $$1}')"
	@echo "----------------------------------------------"
