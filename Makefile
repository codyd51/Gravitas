ARCHS = armv7 arm64
GO_EASY_ON_ME=1
include theos/makefiles/common.mk

TWEAK_NAME = Gravitas
Gravitas_FILES = Listener.xm
Gravitas_FILES += GTController.xm

Gravitas_LIBRARIES = activator

Gravitas_FRAMEWORKS = UIKit
Gravitas_FRAMEWORKS += CoreGraphics
Gravitas_FRAMEWORKS += SpriteKit
Gravitas_FRAMEWORKS += CoreMotion

Graviats_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
