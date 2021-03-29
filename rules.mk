#
# Copyright (C) 2006-2010 OpenWrt.org
# Copyright (C) 2016-2016 tracewong
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

ifneq ($(__rules_inc),1)
__rules_inc=1

ifeq ($(DUMP),)
  -include $(TOPDIR)/.config
endif
include $(TOPDIR)/build/board.mk
include $(TOPDIR)/build/debug.mk
include $(TOPDIR)/build/verbose.mk

export TMP_DIR:=$(TOPDIR)/tmp

qstrip=$(strip $(subst ",,$(1)))
#"))

empty:=
space:= $(empty) $(empty)
comma:=,
merge=$(subst $(space),,$(1))
confvar=$(call merge,$(foreach v,$(1),$(if $($(v)),y,n)))
detectfile=$(call merge,$(foreach v,$(1),$(if $(filter $(v),$(wildcard $(v))),y,)))
detectfile_y=$(call merge,$(foreach v,$(1),y))
strip_last=$(patsubst %.$(lastword $(subst .,$(space),$(1))),%,$(1))

paren_left = (
paren_right = )
chars_lower = a b c d e f g h i j k l m n o p q r s t u v w x y z
chars_upper = A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

define sep

endef

define newline


endef

__tr_list = $(join $(join $(1),$(foreach char,$(1),$(comma))),$(2))
__tr_head_stripped = $(subst $(space),,$(foreach cv,$(call __tr_list,$(1),$(2)),$$$(paren_left)subst$(cv)$(comma)))
__tr_head = $(subst $(paren_left)subst,$(paren_left)subst$(space),$(__tr_head_stripped))
__tr_tail = $(subst $(space),,$(foreach cv,$(1),$(paren_right)))
__tr_template = $(__tr_head)$$(1)$(__tr_tail)

$(eval toupper = $(call __tr_template,$(chars_lower),$(chars_upper)))
$(eval tolower = $(call __tr_template,$(chars_upper),$(chars_lower)))

_SINGLE=export MAKEFLAGS=$(space);
CFLAGS:=
ARCH:=$(call qstrip,$(TARGET_ARCH))
ARCH_PACKAGES:=$(call qstrip,$(TARGET_ARCH_PACKAGES))
BOARD:=$(call qstrip,$(TARGET_BOARD))
TARGET_OPTIMIZATION:=$(call qstrip,$(CONFIG_TARGET_OPTIMIZATION))
export EXTRA_OPTIMIZATION:=$(filter-out -fno-plt,$(call qstrip,$(CONFIG_EXTRA_OPTIMIZATION)))
TARGET_SUFFIX=$(call qstrip,$(CONFIG_TARGET_SUFFIX))
TOOLCHAIN_LIBC=$(call qstrip,$(CONFIG_TOOLCHAIN_LIBC))
BUILD_SUFFIX:=$(call qstrip,$(CONFIG_BUILD_SUFFIX))
SUBDIR:=$(patsubst $(TOPDIR)/%,%,${CURDIR})
BUILD_SUBDIR:=$(patsubst $(TOPDIR)/%,%,${CURDIR})
export SHELL:=/usr/bin/env bash
IS_PACKAGE_BUILD := $(if $(filter package/%,$(BUILD_SUBDIR)),1)

OPTIMIZE_FOR_CPU=$(subst i386,i486,$(ARCH))

ifeq ($(ARCH),powerpc)
  FPIC:=-fPIC
else
  FPIC:=-fpic
endif

HOST_FPIC:=-fPIC

ARCH_SUFFIX:=$(call qstrip,$(CONFIG_CPU_TYPE))
GCC_ARCH:=

ifneq ($(ARCH_SUFFIX),)
  ARCH_SUFFIX:=_$(ARCH_SUFFIX)
endif
ifneq ($(filter -march=armv%,$(TARGET_OPTIMIZATION)),)
  GCC_ARCH:=$(patsubst -march=%,%,$(filter -march=armv%,$(TARGET_OPTIMIZATION)))
endif
ifdef CONFIG_HAS_SPE_FPU
  TARGET_SUFFIX:=$(TARGET_SUFFIX)spe
endif
ifdef CONFIG_MIPS64_ABI
  ifneq ($(CONFIG_MIPS64_ABI_O32),y)
     ARCH_SUFFIX:=$(ARCH_SUFFIX)_$(call qstrip,$(CONFIG_MIPS64_ABI))
  endif
endif

DL_DIR:=$(TOPDIR)/dl
OUT_DIR:=$(TOPDIR)/out
TARGET_OUT_DIR:=$(TOPDIR)/out/$(BOARD)
BUILD_DIR:=$(TOPDIR)/build
SCRIPT_DIR:=$(TOPDIR)/scripts
COMPILE_DIR_BASE:=$(TARGET_OUT_DIR)/compile_dir

ifeq ($(CONFIG_UPDATE_TOOLCHAIN), )
  CONFIG_TARGET_NAME=$(ARCH)-openwrt-linux
  ifeq ($(ARCH), arm)
    CONFIG_TOOLCHAIN_PREFIX=$(ARCH)-openwrt-linux-$(TARGET_SUFFIX)-
  else
    ifeq ($(ARCH), riscv)
      ifeq ($(CONFIG_EXT_TOOLCHAIN_LIBC_USE_GLIBC),y)
        CONFIG_TOOLCHAIN_PREFIX=riscv64-unknown-linux-gnu-
        CONFIG_TARGET_NAME=riscv64-unknown-linux-gnu
      endif
    else
      ifeq ($(CONFIG_COMPLILE_KERNEL64_USER32),y)
        ifeq ($(CONFIG_EXT_TOOLCHAIN_LIBC_USE_GLIBC),y)
            CONFIG_TOOLCHAIN_PREFIX=arm-openwrt-linux-gnueabi-
            CONFIG_TARGET_NAME=arm-openwrt-linux
        else
            CONFIG_TOOLCHAIN_PREFIX=arm-openwrt-linux-muslgnueabi-
            CONFIG_TARGET_NAME=arm-openwrt-linux
        endif
      else
        CONFIG_TOOLCHAIN_PREFIX=$(ARCH)-openwrt-linux-$(TARGET_SUFFIX)-
      endif
    endif
  endif
  ifeq ($(TARGET_CPU_VARIANT),arm926ej-s)
    CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/$(ARCH)/toolchain-sunxi-arm9-$(TOOLCHAIN_LIBC)/toolchain
    TARGET_CFLAGS+=-Wno-unused-result
  else
    ifeq ($(ARCH), riscv)
      CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/$(ARCH)/toolchain-thead-$(TOOLCHAIN_LIBC)/riscv64-linux-x86_64-20200528
    else
      ifeq ($(CONFIG_COMPLILE_KERNEL64_USER32),y)
        ifeq ($(CONFIG_EXT_TOOLCHAIN_GCC_5_3_1),y)
            CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-$(TOOLCHAIN_LIBC)-gcc-531/toolchain
        else
            CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-$(TOOLCHAIN_LIBC)/toolchain
        endif
      else
        ifeq ($(CONFIG_EXT_TOOLCHAIN_GCC_5_3_1),y)
          CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/$(ARCH)/toolchain-sunxi-$(TOOLCHAIN_LIBC)-gcc-531/toolchain
        else
          CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/$(ARCH)/toolchain-sunxi-$(TOOLCHAIN_LIBC)/toolchain
        endif
      endif
    endif
  endif
  CONFIG_TOOLCHAIN_BIN_PATH="./usr/bin ./bin"
  CONFIG_TOOLCHAIN_LIB_PATH="./usr/lib ./lib"
  CONFIG_LIBATOMIC_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBC_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBGCC_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBPTHREAD_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBRT_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBSSP_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBSTDCPP_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
  CONFIG_LIBASAN_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)

  ifneq ($(ARCH), riscv)
    CONFIG_LIBATOMIC_FILE_SPEC="./lib/libatomic.so.*"
    CONFIG_LIBGCC_FILE_SPEC="./lib/libgcc_s.so.*"
    CONFIG_LIBPTHREAD_FILE_SPEC="./lib/libpthread{-*.so,.so.*}"
    CONFIG_LIBRT_FILE_SPEC="./lib/librt{-*.so,.so.*}"
    CONFIG_LIBSSP_FILE_SPEC="./lib/libssp.so.*"
    CONFIG_LIBSTDCPP_FILE_SPEC="./lib/libstdc++.so.*"
    CONFIG_LIBASAN_FILE_SPEC="./lib/libasan.so.*"
  endif

  ifeq ($(CONFIG_TOOLCHAIN_LIBC), "musl")
    CONFIG_TOOLCHAIN_INC_PATH="./usr/include ./include ./include/fortify"
    ifneq ($(ARCH), riscv)
      CONFIG_LIBC_FILE_SPEC="./lib/ld-musl-*.so* ./lib/lib{anl,c,gomp,cidn,crypt,dl,m,nsl,nss_dns,nss_files,resolv,util}{-*.so,.so*}"
    endif
  else ifeq ($(CONFIG_TOOLCHAIN_LIBC), "glibc")
    CONFIG_TOOLCHAIN_INC_PATH="./usr/include ./include"
    ifneq ($(ARCH), riscv)
      CONFIG_LIBC_FILE_SPEC="./lib/ld-{*.so,linux*.so.*} ./lib/lib{anl,c,cidn,gomp,crypt,dl,m,nsl,nss_dns,nss_files,resolv,util}{-*.so,.so*}"
    endif
    CONFIG_LDD_ROOT_DIR=$(CONFIG_TOOLCHAIN_ROOT)
    CONFIG_LDD_FILE_SPEC="./usr/bin/ldd"
  endif
else
  CONFIG_MAKE_TOOLCHAIN:=y
  CONFIG_TOOLCHAIN_ROOT=$(TOPDIR)/prebuilt/gcc/linux-x86/$(ARCH)
endif

ifeq ($(CONFIG_EXTERNAL_TOOLCHAIN),)
  GCCV:=$(call qstrip,$(CONFIG_GCC_VERSION))
  LIBC:=$(call qstrip,$(CONFIG_LIBC))
  LIBCV:=$(call qstrip,$(CONFIG_LIBC_VERSION))
  REAL_GNU_TARGET_NAME=$(OPTIMIZE_FOR_CPU)-openwrt-linux$(if $(TARGET_SUFFIX),-$(TARGET_SUFFIX))
  GNU_TARGET_NAME=$(OPTIMIZE_FOR_CPU)-openwrt-linux
  DIR_SUFFIX:=_$(LIBC)-$(LIBCV)$(if $(CONFIG_arm),_eabi)
  TARGET_DIR_NAME = target
  TOOLCHAIN_DIR_NAME = toolchain
else
  ifeq ($(CONFIG_NATIVE_TOOLCHAIN),)
    GNU_TARGET_NAME=$(call qstrip,$(CONFIG_TARGET_NAME))
  else
    GNU_TARGET_NAME=$(shell gcc -dumpmachine)
  endif
  REAL_GNU_TARGET_NAME=$(GNU_TARGET_NAME)
  TARGET_DIR_NAME:=target
  TOOLCHAIN_DIR_NAME:=toolchain
endif

ifeq ($(or $(CONFIG_EXTERNAL_TOOLCHAIN),$(CONFIG_GCC_VERSION_4_8),$(CONFIG_GCC_VERSION_4_8_3),$(CONFIG_GCC_VERSION_4_5_1),$(CONFIG_TARGET_uml),$(CONFIG_EXT_TOOLCHAIN_GCC_5_3_1)),)
  iremap = -iremap $(1):$(2)
endif

PACKAGE_DIR:=$(TARGET_OUT_DIR)/packages
COMPILE_DIR:=$(COMPILE_DIR_BASE)/$(TARGET_DIR_NAME)
STAGING_DIR:=$(TARGET_OUT_DIR)/staging_dir/$(TARGET_DIR_NAME)
COMPILE_DIR_TOOLCHAIN:=$(COMPILE_DIR_BASE)/$(TOOLCHAIN_DIR_NAME)
TOOLCHAIN_DIR:=$(TARGET_OUT_DIR)/staging_dir/$(TOOLCHAIN_DIR_NAME)
STAMP_DIR:=$(COMPILE_DIR)/stamp
STAMP_DIR_HOST=$(COMPILE_DIR_HOST)/stamp
TARGET_ROOTFS_DIR?=$(if $(call qstrip,$(CONFIG_TARGET_ROOTFS_DIR)),$(call qstrip,$(CONFIG_TARGET_ROOTFS_DIR)),$(COMPILE_DIR))
TARGET_DIR:=$(TARGET_ROOTFS_DIR)/rootfs
STAGING_DIR_ROOT:=$(STAGING_DIR)/rootfs
BUILD_LOG_DIR:=$(TOPDIR)/logs
PKG_INFO_DIR := $(STAGING_DIR)/pkginfo

COMPILE_DIR_HOST:=$(if $(IS_PACKAGE_BUILD),$(COMPILE_DIR)/host,$(COMPILE_DIR_BASE)/host)
STAGING_DIR_HOST:=$(TOPDIR)/out/host

TARGET_PATH:=$(subst $(space),:,$(filter-out .,$(filter-out ./,$(subst :,$(space),$(PATH)))))
TARGET_INIT_PATH:=$(call qstrip,$(CONFIG_TARGET_INIT_PATH))
TARGET_INIT_PATH:=$(if $(TARGET_INIT_PATH),$(TARGET_INIT_PATH),/usr/sbin:/sbin:/usr/bin:/bin)
TARGET_CFLAGS:=$(TARGET_OPTIMIZATION)$(if $(CONFIG_DEBUG), -g3) $(call qstrip,$(CONFIG_EXTRA_OPTIMIZATION))
ifndef ($(or $(CONFIG_GCC_VERSION_4_5_1),$(CONFIG_GCC_VERSION_4_8_3)),)
  TARGET_CFLAGS:=$(filter-out -fno-plt,$(call qstrip,$(TARGET_CFLAGS)))
  TARGET_CFLAGS+=-Wno-unused-result
endif
TARGET_CXXFLAGS = $(TARGET_CFLAGS)
TARGET_ASFLAGS_DEFAULT = $(TARGET_CFLAGS)
TARGET_ASFLAGS = $(TARGET_ASFLAGS_DEFAULT)
TARGET_CPPFLAGS:=-I$(STAGING_DIR)/usr/include -I$(STAGING_DIR)/include
TARGET_LDFLAGS:=-L$(STAGING_DIR)/usr/lib -L$(STAGING_DIR)/lib
ifneq ($(CONFIG_EXTERNAL_TOOLCHAIN),)
LIBGCC_S_PATH=$(realpath $(wildcard $(call qstrip,$(CONFIG_LIBGCC_ROOT_DIR))/$(call qstrip,$(CONFIG_LIBGCC_FILE_SPEC))))
LIBGCC_S=$(if $(LIBGCC_S_PATH),-L$(dir $(LIBGCC_S_PATH)) -lgcc_s)
LIBGCC_A=$(realpath $(lastword $(wildcard $(dir $(LIBGCC_S_PATH))/gcc/*/*/libgcc.a)))
else
LIBGCC_A=$(lastword $(wildcard $(TOOLCHAIN_DIR)/lib/gcc/*/*/libgcc.a))
LIBGCC_S=$(if $(wildcard $(TOOLCHAIN_DIR)/lib/libgcc_s.so),-L$(TOOLCHAIN_DIR)/lib -lgcc_s,$(LIBGCC_A))
endif
LIBRPC=-lrpc
LIBRPC_DEPENDS=+librpc

ifeq ($(CONFIG_ARCH_64BIT),y)
  LIB_SUFFIX:=64
endif

ifndef DUMP
  ifeq ($(CONFIG_EXTERNAL_TOOLCHAIN),)
    -include $(TOOLCHAIN_DIR)/info.mk
    export GCC_HONOUR_COPTS:=0
    TARGET_CROSS:=$(if $(TARGET_CROSS),$(TARGET_CROSS),$(OPTIMIZE_FOR_CPU)-openwrt-linux$(if $(TARGET_SUFFIX),-$(TARGET_SUFFIX))-)
    ifdef ($(or $(CONFIG_GCC_VERSION_4_5_1),$(CONFIG_GCC_VERSION_4_8_3)),)
      TARGET_CFLAGS+= -fhonour-copts -Wno-error=unused-but-set-variable -Wno-error=unused-result
    endif
    TARGET_CPPFLAGS+= -I$(TOOLCHAIN_DIR)/usr/include
    ifeq ($(CONFIG_USE_MUSL),y)
      TARGET_CPPFLAGS+= -I$(TOOLCHAIN_DIR)/include/fortify
    endif
    TARGET_CPPFLAGS+= -I$(TOOLCHAIN_DIR)/include
    TARGET_LDFLAGS+= -L$(TOOLCHAIN_DIR)/usr/lib -L$(TOOLCHAIN_DIR)/lib
    TARGET_PATH:=$(TOOLCHAIN_DIR)/bin:$(TARGET_PATH)
  else
    ifeq ($(CONFIG_NATIVE_TOOLCHAIN),)
      TARGET_CROSS:=$(call qstrip,$(CONFIG_TOOLCHAIN_PREFIX))
      TOOLCHAIN_ROOT_DIR:=$(call qstrip,$(CONFIG_TOOLCHAIN_ROOT))
      TOOLCHAIN_BIN_DIRS:=$(patsubst ./%,$(TOOLCHAIN_ROOT_DIR)/%,$(call qstrip,$(CONFIG_TOOLCHAIN_BIN_PATH)))
      TOOLCHAIN_INC_DIRS:=$(patsubst ./%,$(TOOLCHAIN_ROOT_DIR)/%,$(call qstrip,$(CONFIG_TOOLCHAIN_INC_PATH)))
      TOOLCHAIN_LIB_DIRS:=$(patsubst ./%,$(TOOLCHAIN_ROOT_DIR)/%,$(call qstrip,$(CONFIG_TOOLCHAIN_LIB_PATH)))
      ifneq ($(TOOLCHAIN_BIN_DIRS),)
        TARGET_PATH:=$(subst $(space),:,$(TOOLCHAIN_BIN_DIRS)):$(TARGET_PATH)
      endif
      ifneq ($(TOOLCHAIN_INC_DIRS),)
        TARGET_CPPFLAGS+= $(patsubst %,-I%,$(TOOLCHAIN_INC_DIRS))
      endif
      ifneq ($(TOOLCHAIN_LIB_DIRS),)
        TARGET_LDFLAGS+= $(patsubst %,-L%,$(TOOLCHAIN_LIB_DIRS))
      endif
      TARGET_CXXFLAGS+=-Wno-virtual-dtor
      ifeq ($(CONFIG_COMPLILE_KERNEL64_USER32),y)
         ARCH64PATH:=$(TOPDIR)/prebuilt/gcc/linux-x86/aarch64/toolchain-sunxi-$(TOOLCHAIN_LIBC)/toolchain
         TARGET_PATH:=$(TOOLCHAIN_DIR)/bin:$(TARGET_PATH):$(ARCH64PATH)/bin
      else
         TARGET_PATH:=$(TOOLCHAIN_DIR)/bin:$(TARGET_PATH)
      endif
   endif
  endif
endif
TARGET_PATH_PKG:=$(STAGING_DIR)/host/bin:$(TARGET_PATH)

ifeq ($(CONFIG_SOFT_FLOAT),y)
  SOFT_FLOAT_CONFIG_OPTION:=--with-float=soft
  ifeq ($(CONFIG_arm),y)
    TARGET_CFLAGS+= -mfloat-abi=soft
  else
    TARGET_CFLAGS+= -msoft-float
  endif
else
  SOFT_FLOAT_CONFIG_OPTION:=
  ifeq ($(or $(CONFIG_arm),$(CONFIG_COMPLILE_KERNEL64_USER32)),y)
    ifeq ($(CONFIG_COMPLILE_KERNEL64_USER32),y)
      TARGET_CFLAGS +=-Os -pipe -march=armv8-a -mtune=cortex-a53 -mfpu=neon
    endif
    TARGET_CFLAGS+= -mfloat-abi=hard
  endif
endif

export PATH:=$(TARGET_PATH)
export STAGING_DIR STAGING_DIR_HOST
export SH_FUNC:=. $(BUILD_DIR)/shell.sh;

PKG_CONFIG:=$(STAGING_DIR_HOST)/bin/pkg-config

export PKG_CONFIG

HOSTCC:=gcc
HOSTCXX:=g++
HOST_CPPFLAGS:=-I$(STAGING_DIR_HOST)/include -I$(STAGING_DIR_HOST)/usr/include $(if $(IS_PACKAGE_BUILD),-I$(STAGING_DIR)/host/include)
HOST_CFLAGS:=-O2 $(HOST_CPPFLAGS)
HOST_LDFLAGS:=-L$(STAGING_DIR_HOST)/lib -L$(STAGING_DIR_HOST)/usr/lib $(if $(IS_PACKAGE_BUILD),-L$(STAGING_DIR)/host/lib)

ifeq ($(or $(CONFIG_EXTERNAL_TOOLCHAIN),$(CONFIG_GCC_VERSION_4_5_1),$(CONFIG_GCC_VERSION_4_8_3)),)
  TARGET_AR:=$(TARGET_CROSS)gcc-ar
  TARGET_RANLIB:=$(TARGET_CROSS)gcc-ranlib
  TARGET_NM:=$(TARGET_CROSS)gcc-nm
else
  TARGET_AR:=$(TARGET_CROSS)ar
  TARGET_RANLIB:=$(TARGET_CROSS)ranlib
  TARGET_NM:=$(TARGET_CROSS)nm
endif

BUILD_KEY=$(TOPDIR)/key-build

TARGET_CC:=$(TARGET_CROSS)gcc
TARGET_CXX:=$(TARGET_CROSS)g++
KPATCH:=$(SCRIPT_DIR)/patch-kernel.sh
SED:=$(STAGING_DIR_HOST)/bin/sed -i -e
CP:=cp -fpR
LN:=ln -sf
XARGS:=xargs -r

BASH:=bash
TAR:=tar
FIND:=find
PATCH:=patch
PYTHON:=python

INSTALL_BIN:=install -m0755
INSTALL_DIR:=install -d -m0755
INSTALL_DATA:=install -m0644
INSTALL_CONF:=install -m0600

TARGET_CC_NOCACHE:=$(TARGET_CC)
TARGET_CXX_NOCACHE:=$(TARGET_CXX)
HOSTCC_NOCACHE:=$(HOSTCC)
HOSTCXX_NOCACHE:=$(HOSTCXX)
export TARGET_CC_NOCACHE
export TARGET_CXX_NOCACHE
export HOSTCC_NOCACHE

ifneq ($(CONFIG_CCACHE),)
  TARGET_CC:= ccache_cc
  TARGET_CXX:= ccache_cxx
  HOSTCC:= ccache $(HOSTCC)
  HOSTCXX:= ccache $(HOSTCXX)
endif

TARGET_CONFIGURE_OPTS = \
  AR="$(TARGET_AR)" \
  AS="$(TARGET_CC) -c $(TARGET_ASFLAGS)" \
  LD=$(TARGET_CROSS)ld \
  NM="$(TARGET_NM)" \
  CC="$(TARGET_CC)" \
  GCC="$(TARGET_CC)" \
  CXX="$(TARGET_CXX)" \
  RANLIB="$(TARGET_RANLIB)" \
  STRIP=$(TARGET_CROSS)strip \
  OBJCOPY=$(TARGET_CROSS)objcopy \
  OBJDUMP=$(TARGET_CROSS)objdump \
  SIZE=$(TARGET_CROSS)size

# strip an entire directory
ifneq ($(CONFIG_NO_STRIP),)
  RSTRIP:=:
  STRIP:=:
else
  ifneq ($(CONFIG_USE_STRIP),)
    STRIP:=$(TARGET_CROSS)strip $(call qstrip,$(CONFIG_STRIP_ARGS))
  else
    ifneq ($(CONFIG_USE_SSTRIP),)
      STRIP:=$(STAGING_DIR_HOST)/bin/sstrip
    endif
  endif
  RSTRIP= \
    export CROSS="$(TARGET_CROSS)" \
		$(if $(PKG_BUILD_ID),KEEP_BUILD_ID=1) \
		$(if $(CONFIG_KERNEL_KALLSYMS),NO_RENAME=1) \
		$(if $(CONFIG_KERNEL_PROFILING),KEEP_SYMBOLS=1); \
    NM="$(TARGET_CROSS)nm" \
    STRIP="$(STRIP)" \
    STRIP_KMOD="$(SCRIPT_DIR)/strip-kmod.sh" \
    PATCHELF="$(STAGING_DIR_HOST)/bin/patchelf" \
    $(SCRIPT_DIR)/rstrip.sh
endif

ifeq ($(CONFIG_IPV6),y)
  DISABLE_IPV6:=
else
  DISABLE_IPV6:=--disable-ipv6
endif

TAR_OPTIONS:=-xf -

ifeq ($(CONFIG_BUILD_LOG),y)
  BUILD_LOG:=1
endif

export BISON_PKGDATADIR:=$(STAGING_DIR_HOST)/share/bison
export M4:=$(STAGING_DIR_HOST)/bin/m4

define shvar
V_$(subst .,_,$(subst -,_,$(subst /,_,$(1))))
endef

define shexport
export $(call shvar,$(1))=$$(call $(1))
endef

define include_mk
$(eval -include $(if $(DUMP),,$(STAGING_DIR)/mk/$(strip $(1))))
endef

# Execute commands under flock
# $(1) => The shell expression.
# $(2) => The lock name. If not given, the global lock will be used.
ifneq ($(wildcard $(STAGING_DIR_HOST)/bin/flock),)
  define locked
	SHELL= \
	flock \
		$(TMP_DIR)/.$(if $(2),$(strip $(2)),global).flock \
		-c '$(subst ','\'',$(1))'
  endef
else
  locked=$(1)
endif

# Recursively copy paths into another directory, purge dangling
# symlinks before.
# $(1) => File glob expression
# $(2) => Destination directory
define file_copy
	for src_dir in $(sort $(foreach d,$(wildcard $(1)),$(dir $(d)))); do \
		( cd $$src_dir; find -type f -or -type d ) | \
			( cd $(2); while :; do \
				read FILE; \
				[ -z "$$FILE" ] && break; \
				[ -L "$$FILE" ] || continue; \
				echo "Removing symlink $(2)/$$FILE"; \
				rm -f "$$FILE"; \
			done; ); \
	done; \
	$(CP) $(1) $(2)
endef

# file extension
ext=$(word $(words $(subst ., ,$(1))),$(subst ., ,$(1)))

all:
FORCE: ;
.PHONY: FORCE

val.%:
	@$(if $(filter undefined,$(origin $*)),\
		echo "$* undefined" >&2, \
		echo '$(subst ','"'"',$($*))' \
	)

var.%:
	@$(if $(filter undefined,$(origin $*)),\
		echo "$* undefined" >&2, \
		echo "$*='"'$(subst ','"'\"'\"'"',$($*))'"'" \
	)

endif #__rules_inc
