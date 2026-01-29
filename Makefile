# InputLocker Makefile

APP_NAME = InputLocker
BUNDLE_NAME = $(APP_NAME).app
BUILD_DIR = build
CONTENTS_DIR = $(BUILD_DIR)/$(BUNDLE_NAME)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SOURCES = main.swift AppDelegate.swift InputSourceManager.swift
FRAMEWORKS = -framework Cocoa -framework Carbon

all: clean build

build:
	@echo "正在编译 $(APP_NAME)..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)

	@swiftc $(SOURCES) $(FRAMEWORKS) -o $(MACOS_DIR)/$(APP_NAME)

	@cp Info.plist $(CONTENTS_DIR)/

	@echo "编译完成！应用位于: $(BUILD_DIR)/$(BUNDLE_NAME)"

clean:
	@echo "清理构建目录..."
	@rm -rf $(BUILD_DIR)

run: build
	@echo "启动 $(APP_NAME)..."
	@open $(BUILD_DIR)/$(BUNDLE_NAME)

install: build
	@echo "安装到 /Applications..."
	@cp -r $(BUILD_DIR)/$(BUNDLE_NAME) /Applications/
	@echo "安装完成！"

.PHONY: all build clean run install
