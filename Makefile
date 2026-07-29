THEOS_DEVICE_IP = 192.168.0.251
THEOS_PACKAGE_SCHEME=rootless
ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = YouTubeMusic
include $(THEOS)/makefiles/common.mk
LASTFM_API_KEY = 3a786bb0ba066718c083ab3c316e7585
LASTFM_API_SECRET = 69dc74de5bb43846ac88573c243e4a0a
TWEAK_NAME = LastFMYouTubeMusic
$(TWEAK_NAME)_FILES = $(shell find sources -name "*.x*")
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -DAPI_KEY=@\"$(LASTFM_API_KEY)\" -DAPI_SECRET=@\"$(LASTFM_API_SECRET)\"
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CydiaSubstrate MediaPlayer
include $(THEOS_MAKE_PATH)/tweak.mk
