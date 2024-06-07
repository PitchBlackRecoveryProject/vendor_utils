WORK_PATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/zip
TARGET_DIR := $(WORK_PATH)/..
BUILD_TOP := $(TOP)
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

ZIP_NAME := PBRP-$(TARGET_DEVICE)-$(VERSION)-$(shell date +%Y%m%d-%H%M)-$(PB_BUILD_TYPE).zip
KEYCHECK := $(TARGET_DIR)/recovery/root/sbin/keycheck
AB := false
ifeq ($(BOARD_USES_RECOVERY_AS_BOOT), true)
    RECOVERY_AS_BOOT := true
    RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/ramdisk-recovery.cpio
    pbrpimage=$(INSTALLED_BOOTIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)
else
    RECOVERYPATH := $(OUT_DIR)/target/product/$(TARGET_DEVICE)/recovery.img
    RECOVERY_AS_BOOT := false
    pbrpimage=$(INSTALLED_RECOVERYIMAGE_TARGET) $(RECOVERY_RESOURCE_ZIP)
endif

.PHONY: pbrp
pbrp: $(pbrpimage)
	$(hide) rm -f $(TARGET_DIR)/*.zip
	$(hide) rm -rf $(WORK_PATH) && mkdir $(WORK_PATH);
	$(hide) rsync -avp $(PB_VENDOR)/PBRP $(WORK_PATH)/;
	$(hide) mkdir -p $(WORK_PATH)/META-INF/com/google/android
	$(hide) rsync -avp $(PB_VENDOR)/updater/update-* $(WORK_PATH)/META-INF/com/google/android/
	$(hide) sed -i "s:{version}:v$(VERSION):g" $(WORK_PATH)/META-INF/com/google/android/update-binary
	echo "dsfsdfsdf"
	$(hide) if [ "$(RECOVERY_AS_BOOT)" == "true" ]; then sed -i "s:IS_AB=false:IS_AB=true:" $(WORK_PATH)/META-INF/com/google/android/update-binary; fi
	echo "dsfsdfsdf2255"
	$(hide) rsync -avp $(PB_VENDOR)/updater/awk $(WORK_PATH)/META-INF/
	$(hide) rsync -avp $(BUILD_TOP)/external/magisk-prebuilt/prebuilt/magiskboot_arm $(WORK_PATH)/magiskboot;
	$(hide) chmod +x $(WORK_PATH)/magiskboot;
	$(hide) if [ -f $(KEYCHECK) ]; then cp $(KEYCHECK) $(WORK_PATH)/META-INF/; fi
	$(hide) cp $(RECOVERYPATH) $(WORK_PATH)/;
	$(hide) cd $(WORK_PATH) && zip -r $(ZIP_NAME) *;
	$(hide) cd $(BUILD_TOP) && mv $(WORK_PATH)/$(ZIP_NAME) $(WORK_PATH)/../
	$(hide) cat $(BUILD_TOP)/vendor/utils/.pb.1
	printf "Recovery Image: %s\n" "$(RECOVERYPATH)"
	printf "Size: %s\n" "$$(du -h $(RECOVERYPATH) | awk '{print $$1}')"
	printf "Flashable Zip: %s\n" "$(OUT_DIR)/target/product/${TARGET_DEVICE}/$(ZIP_NAME)"
	printf "Size: %s\n" "$$(du -h $(WORK_PATH)/../$(ZIP_NAME) | awk '{print $$1}')"
