THEOS ?= /var/mobile/theos
export THEOS
ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Ledger

Ledger_FILES = main.m \
               LedgerAppDelegate.m \
               LedgerRecord.m \
               LedgerStore.m \
               LedgerRootViewController.m \
               LedgerDayViewController.m \
               LedgerMonthViewController.m \
               LedgerYearViewController.m \
               LedgerStatsViewController.m \
               LedgerAddViewController.m

Ledger_FRAMEWORKS = UIKit CoreGraphics
Ledger_CFLAGS = -fobjc-arc
Ledger_LDFLAGS = -lc++
Ledger_INSTALL_PERMISSIONS = root wheel

THEOS_PACKAGE_SCHEME = rootless
Ledger_CODESIGN_FLAGS = -Sents.plist

include $(THEOS)/makefiles/application.mk

internal-package::
	@echo "正在生成IPA文件..."
	@mkdir -p $(THEOS_STAGING_DIR)/Payload
	@cp -r $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app $(THEOS_STAGING_DIR)/Payload/
	@cd $(THEOS_STAGING_DIR) && zip -qr ../$(APPLICATION_NAME).ipa Payload
	@echo "IPA文件生成完成"
