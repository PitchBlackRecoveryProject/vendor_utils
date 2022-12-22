WORK_PATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/zip
BUILD_TOP := $(OUT_DIR)/../
VERSION := $(shell cat $(BUILD_TOP)/bootable/recovery/variables.h | egrep "define\s+PB_MAIN_VERSION" | tr -d '"' | tr -s ' ' | awk '{ print $$3 }')
PB_VENDOR := vendor/utils
ifeq ($(PB_OFFICIAL),true)
    PB_BUILD_TYPE := OFFICIAL
    ifneq ($(shell python3 $(BUILD_TOP)/vendor/utils/pb_devices.py verify all $(TARGET_DEVICE); echo $$?),0)
        $(call error Device is not official)
    endif
else ifeq ($(BETA_BUILD),true)
    PB_BUILD_TYPE := BETA
    ifneq ($(shell python3 $(BUILD_TOP)/vendor/utils/pb_devices.py verify all $(TARGET_DEVICE); echo $$?),0)
        $(call error Device is not official)
    endif
else
    PB_BUILD_TYPE := UNOFFICIAL
endif
ifeq ($(PB_VARIANT), default)
ZIP_NAME := PBRP-$(TARGET_DEVICE)-$(VERSION)-$(shell date +%Y%m%d-%H%M)-$(PB_BUILD_TYPE).zip
else
ZIP_NAME := PBRP-$(TARGET_DEVICE)-$(VERSION)-$(PB_VARIANT)-$(shell date +%Y%m%d-%H%M)-$(PB_BUILD_TYPE).zip
endif
RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/recovery.img
KEYCHECK := $(OUT_DIR)/recovery/root/sbin/keycheck
AB := false
ifeq ($(AB_OTA_UPDATER), true)
    AB := true
endif
ifeq ($(BOARD_USES_RECOVERY_AS_BOOT), true)
    RECOVERY_AS_BOOT := true
    pbrpimage=$(INSTALLED_BOOTIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)
else
    pbrpimage=$(INSTALLED_RECOVERYIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)
endif

.PHONY: pbrp
pbrp: $(pbrpimage)
	$(hide) rm -f $(WORK_PATH)/../*.zip
	$(hide) if [ -d $(WORK_PATH) ]; then rm -rf $(WORK_PATH); fi
	$(hide) mkdir $(WORK_PATH)
	$(hide) rsync -avp $(PB_VENDOR)/PBRP $(WORK_PATH)/
	$(hide) mkdir -p $(WORK_PATH)/META-INF/com/google/android
	$(hide) rsync -avp $(PB_VENDOR)/updater/update-* $(WORK_PATH)/META-INF/com/google/android/
	$(hide) rsync -avp $(PB_VENDOR)/updater/awk $(WORK_PATH)/META-INF/
	$(hide) rsync -avp $(PB_VENDOR)/updater/magiskboot $(WORK_PATH)/
	$(hide) if [ -f $(KEYCHECK) ]; then cp $(KEYCHECK) $(WORK_PATH)/META-INF/; fi
	$(hide) if [ "$(AB)" == "true" ]; then sed -i "s|AB_DEVICE=false|AB_DEVICE=true|g" $(WORK_PATH)/META-INF/com/google/android/update-binary; fi
	$(hide) if [ "$(RECOVERY_AS_BOOT)" == "true" ]; then sed -i "s|USES_RECOVERY_AS_BOOT=false|USES_RECOVERY_AS_BOOT=true|g" $(WORK_PATH)/META-INF/com/google/android/update-binary; fi
	$(hide) mkdir $(WORK_PATH)/TWRP
	$(hide) if [ -e $(WORK_PATH)/../boot.img ]; then cp $(WORK_PATH)/../boot.img $(WORK_PATH)/../recovery.img; fi
	$(hide) cp $(WORK_PATH)/../recovery.img $(WORK_PATH)/TWRP/
	$(hide) cd $(WORK_PATH) && zip -r $(ZIP_NAME) *
	$(hide) cd $(BUILD_TOP) && mv $(WORK_PATH)/$(ZIP_NAME) $(WORK_PATH)/../
	$(hide) cat $(BUILD_TOP)/vendor/utils/.pb.1
	printf "Recovery Image: %s\n" "$(RECOVERYPATH)"
	printf "Size: %s\n" "$$(du -h $(RECOVERYPATH) | awk '{print $$1}')"
	printf "Flashable Zip: %s\n" "$(OUT_DIR)/target/product/${TARGET_DEVICE}/$(ZIP_NAME)"
	printf "Size: %s\n" "$$(du -h $(WORK_PATH)/../$(ZIP_NAME) | awk '{print $$1}')"
